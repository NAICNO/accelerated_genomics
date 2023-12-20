#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process pbrun_deepvariant {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/deepvariant", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM),
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)
    path(TARGET_REGIONS)

    output:
    tuple val(S_NAME), path("${BAM}.deepvariant.vcf"), emit: deepvariant


    script:
    template 'pbrun_deepvariant.sh'

}