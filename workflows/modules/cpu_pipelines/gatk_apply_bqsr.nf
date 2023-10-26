#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_apply_bqsr {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(RECAL)
    tuple val(S_NAME), path(BAM), path(BAI)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${BAM}_BQSR.bam"), path("${BAM}_BQSR*bai"), emit: apply_bqsr

    script:
    template 'gatk_apply_bqsr.sh'

}