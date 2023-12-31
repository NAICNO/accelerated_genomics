#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_mark_dup {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${BAM}_markdup.bam"), path("${BAM}_markdup*bai"), emit: markdup_bam

    script:
    template 'gatk_mark_dup.sh'

}