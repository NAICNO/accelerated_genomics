#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process pbrun_haplotypecaller {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/haplotypeCaller", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)
    path(TARGET_REGIONS)

    output:
    tuple val(S_NAME), path("${BAM}.vcf"), emit: haplotypeCaller

    script:
    template 'pbrun_haplotypecaller.sh'

}