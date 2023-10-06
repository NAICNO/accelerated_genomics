#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_sort {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(SAM)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${SAM}.bam"), emit: sort_bam

    script:
    template 'gatk_sort_coordinate.sh'

}