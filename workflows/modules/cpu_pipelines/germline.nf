#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

include { bwa                   } from './bwa_mapping'
include { gatk_sort             } from './gatk_sort_coordinate'
include { gatk_mark_dup         } from './gatk_mark_dup'
include { gatk_bqsr             } from './gatk_bqsr'
include { gatk_apply_bqsr       } from './gatk_apply_bqsr'
include { gatk_haplotypeCaller  } from './gatk_haplotype'
include { deepvariant           } from './deepvariant'

def PROCESSOR = "CPU"

workflow germline_cpu {

    take:
    input_fqs
    genome_folder
    reference_map
    target_regions

    main:

    // BWA mapping
    bwa(
        input_fqs, genome_folder, reference_map, PROCESSOR
    )

    // GATK MarkDuplicates
    gatk_mark_dup(bwa.out.bwa_bam, PROCESSOR)

    // GATK BaseRecalibrator
    gatk_bqsr(gatk_mark_dup.out.markdup_bam, genome_folder, reference_map, target_regions, PROCESSOR)

    // GATK ApplyBQSR
    gatk_apply_bqsr(gatk_bqsr.out.bqsr, gatk_mark_dup.out.markdup_bam, genome_folder, reference_map, target_regions, PROCESSOR)

    // GATK HaplotypeCaller
    gatk_haplotypeCaller(gatk_apply_bqsr.out.apply_bqsr, genome_folder, reference_map, target_regions, PROCESSOR)

    // DeeepVariant
    deepvariant(gatk_apply_bqsr.out.apply_bqsr, genome_folder, reference_map, target_regions, PROCESSOR)

}