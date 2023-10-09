#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
def PROCESSOR = "GPU"

include { fq2bam } from './pbrun_fq2bam'
include { haplotypecaller } from './pbrun_haplotypecaller'

workflow germline {
    take:
    input_fqs
    genome_folder
    reference_map

    main:

    // pbrun fq2bam: mapping, GATK sort by coordinate, GATK MarkDuplicates, GATK BaseRecalibrator and 
    fq2bam(
        input_fqs, genome_folder, reference_map, PROCESSOR
    )

    // pbrun haplotypecaller:GATK ApplyBQSR
    haplotypecaller(
        fq2bam.out.fq2bam, genome_folder, reference_map, PROCESSOR
    )

}