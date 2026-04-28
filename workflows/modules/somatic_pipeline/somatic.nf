#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Existing imports
include { pbrun_fq2bam          } from '../gpu_pipelines/pbrun_fq2bam'
include { pbrun_applybqsr       } from '../gpu_pipelines/pbrun_applybqsr'
// New import for Somatic calling
include { parabricks_mutect     } from './parabricks_mutect' 

workflow somatic_mutect {

    take:
    samples_ch      // Channel: [val(pair_id), [path(normal_r1), path(normal_r2)], [path(tumor_r1), path(tumor_r2)]]
    genome_folder
    reference_map
    target_regions

    main:
    def processor = "GPU" // Parabricks typically requires GPU
    
    // 1. Flatten the pairs to process Normal and Tumor through the same preprocessing steps
    // Resulting channel: [val(sample_id), path(r1), path(r2)] where sample_id ends with __normal or __tumor.
    ch_to_process = samples_ch
        .flatMap { id, normal_reads, tumor_reads ->
            assert normal_reads.size() == 2 && tumor_reads.size() == 2 : "Expected paired-end FASTQs for pair ${id}"
            [
                ["${id}__normal", normal_reads[0], normal_reads[1]],
                ["${id}__tumor",  tumor_reads[0],  tumor_reads[1]]
            ]
        }

    // 2. Alignment & Preprocessing (Follows your diagram)
    pbrun_fq2bam(ch_to_process, genome_folder, reference_map, processor, target_regions)

    pbrun_applybqsr(pbrun_fq2bam.out.fq2bam, genome_folder, reference_map, processor, target_regions)

    // 3. Re-grouping Normal and Tumor BAMs for Mutect
    // Build deterministic [pair_id, normal_bam, normal_bai, tumor_bam, tumor_bai] tuples.
    mutect_input = pbrun_applybqsr.out.applybqsr
        .map { sample_id, bam, bai ->
            def m = (sample_id =~ /(.+)__(normal|tumor)$/)
            assert m.matches() : "Unexpected sample id format: ${sample_id}"
            [m[0][1], m[0][2], bam, bai] // pair_id, type, bam, bai
        }
        .groupTuple(by: 0)
        .map { pair_id, types, bams, bais ->
            def normal_idx = types.indexOf('normal')
            def tumor_idx = types.indexOf('tumor')
            assert normal_idx != -1 && tumor_idx != -1 : "Missing normal or tumor BAM for pair ${pair_id}"
            [pair_id, bams[normal_idx], bais[normal_idx], bams[tumor_idx], bais[tumor_idx]]
        }

    // 4. Parabricks MutectCaller
    parabricks_mutect(
        mutect_input, 
        genome_folder, 
        reference_map, 
        processor,
        target_regions
    )
}