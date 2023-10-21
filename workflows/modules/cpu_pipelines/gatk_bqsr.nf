#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_bqsr {
    publishDir "Results/${PROCESSOR}/${S_NAME}/metadata/gatk/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_${PROCESSOR}_recal.txt"), emit: bqsr

    script:
    template 'gatk_bqsr.sh'

}