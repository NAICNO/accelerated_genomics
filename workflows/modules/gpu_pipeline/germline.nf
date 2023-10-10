#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

include { pbrun_fq2bam          } from './pbrun_fq2bam'
include { pbrun_haplotypecaller } from './pbrun_haplotypecaller'

def PROCESSOR = "GPU"

workflow germline {
    take:
    input_fqs
    genome_folder
    reference_map

    main:

    // pbrun fq2bam: mapping, GATK sort by coordinate, GATK MarkDuplicates, GATK BaseRecalibrator and 
    pbrun_fq2bam(
        input_fqs, genome_folder, reference_map, PROCESSOR
    )

    // pbrun haplotypecaller:GATK ApplyBQSR
    pbrun_haplotypecaller(
        fq2bam.out.fq2bam, genome_folder, reference_map, PROCESSOR
    )

}