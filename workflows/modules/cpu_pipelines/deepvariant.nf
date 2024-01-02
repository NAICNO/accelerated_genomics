#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process deepvariant {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/deepvariant", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    path(REF)
    val(REF_MAP)
    val(TARGET_REGIONS)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${BAM}.vcf"), emit: haplotypeCaller

    script:
    template 'deepvariant.sh'

}