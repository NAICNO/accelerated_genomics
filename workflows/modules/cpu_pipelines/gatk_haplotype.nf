#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_haplotypeCaller {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/haplotypeCaller", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${BAM}.vcf"), emit: haplotypeCaller

    script:
    template 'gatk_haplotype.sh'

}