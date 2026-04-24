#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Existing imports
include { pbrun_fq2bam          } from '../gpu_pipelines/pbrun_fq2bam'
include { pbrun_applybqsr       } from '../gpu_pipelines/pbrun_applybqsr'
include { pbrun_haplotypecaller } from '../gpu_pipelines/pbrun_haplotypecaller'
include { pbrun_deepvariant     } from '../gpu_pipelines/pbrun_deepvariant'
// New import for Somatic calling
include { pabr_mutectcaller     } from './parabricks_mutect' 

def PROCESSOR = "GPU" // Parabricks typically requires GPU

workflow somatic_mutect {

    take:
    samples_ch      // Channel: [val(pair_id), path(normal_fq), path(tumor_fq)]
    genome_folder
    reference_map
    target_regions

    main:
    
    // 1. Flatten the pairs to process Normal and Tumor through the same preprocessing steps
    // Resulting channel: [val(pair_id), val(type), path(fq)]
    ch_to_process = samples_ch
        .flatMap { id, normal, tumor -> 
            [[id, 'normal', normal], [id, 'tumor', tumor]] 
        }

    // 2. Alignment & Preprocessing (Follows your diagram)
    pbrun_fq2bam(ch_to_process, genome_folder, reference_map, PROCESSOR)
    
    pbrun_mark_dup(pbrun_fq2bam.out.bwa_bam, PROCESSOR)
    
    pbrun_bqsr(pbrun_mark_dup.out.markdup_bam, genome_folder, reference_map, target_regions, PROCESSOR)
    
    pbrun_applybqsr(pbrun_bqsr.out.bqsr, pbrun_mark_dup.out.markdup_bam, genome_folder, reference_map, target_regions, PROCESSOR)

    // 3. Re-grouping Normal and Tumor BAMs for Mutect
    // We group by the pair_id and branch based on the type ('normal' or 'tumor')
    mutect_input = pbrun_applybqsr.out.apply_bqsr
        .map { meta, bam, bai -> [ meta[0], meta[1], bam, bai ] } // pair_id, type, bam, bai
        .groupTuple(by: 0) 
        // Logic: meta[0] is pair_id, we now have [pair_id, [normal, tumor], [bam_n, bam_t], [bai_n, bai_t]]

    // 4. Parabricks MutectCaller
    pabr_mutectcaller(
        mutect_input, 
        genome_folder, 
        reference_map, 
        target_regions
    )
}