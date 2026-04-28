#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Existing imports
include { pbrun_fq2bam          } from '../gpu_pipelines/pbrun_fq2bam'
include { pbrun_applybqsr       } from '../gpu_pipelines/pbrun_applybqsr'
// New import for Somatic calling
include { parabricks_mutect     } from './parabricks_mutect' 

workflow somatic_mutect {

    take:
    samples_ch      // Channel: [val(pair_id), path(normal_fq), path(tumor_fq)]
    genome_folder
    reference_map
    target_regions

    main:
    def processor = "GPU" // Parabricks typically requires GPU
    
    // 1. Flatten the pairs to process Normal and Tumor through the same preprocessing steps
    // Resulting channel: [val(pair_id), val(type), path(fq)]
    ch_to_process = samples_ch
        .flatMap { id, normal, tumor -> 
            [[id, 'normal', normal], [id, 'tumor', tumor]] 
        }

    // 2. Alignment & Preprocessing (Follows your diagram)
    pbrun_fq2bam(ch_to_process, genome_folder, reference_map, processor, target_regions)

    pbrun_applybqsr(pbrun_fq2bam.out.fq2bam, genome_folder, reference_map, processor, target_regions)

    // 3. Re-grouping Normal and Tumor BAMs for Mutect
    // Build deterministic [pair_id, normal_bam, normal_bai, tumor_bam, tumor_bai] tuples.
    mutect_input = pbrun_applybqsr.out.applybqsr
        .map { meta, bam, bai -> [ meta[0], meta[1], bam, bai ] } // pair_id, type, bam, bai
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