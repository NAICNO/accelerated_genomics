#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

include { pbrun_fq2bam          } from './pbrun_fq2bam'
include { pbrun_applybqsr       } from './pbrun_applybqsr'
include { pbrun_haplotypecaller } from './pbrun_haplotypecaller'
include { pbrun_deepvariant     } from './pbrun_deepvariant'

def PROCESSOR = "GPU"

workflow germline_gpu {
    take:
    input_fqs
    genome_folder
    reference_map
    target_regions

    main:

    // pbrun fq2bam: mapping, GATK sort by coordinate, GATK MarkDuplicates, GATK BaseRecalibrator and 
    pbrun_fq2bam(
        input_fqs, genome_folder, reference_map, PROCESSOR, target_regions
    )

    // pbrun ApplyBQSR
    pbrun_applybqsr(
        pbrun_fq2bam.out.fq2bam, genome_folder, reference_map, PROCESSOR, target_regions
    )

    // pbrun haplotypecaller
    pbrun_haplotypecaller(
        pbrun_applybqsr.out.applybqsr, genome_folder, reference_map, PROCESSOR, target_regions
    )

    // pbrun deepvariant
    pbrun_deepvariant(
        pbrun_applybqsr.out.applybqsr, genome_folder, reference_map, PROCESSOR, target_regions
    )

}