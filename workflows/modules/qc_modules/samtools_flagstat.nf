#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process samtools_flagstat {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME)
    tuple path(BAM), path(BAI)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_samtools_flagstat_${PROCESSOR}.txt"), emit: flagstat

    script:
    template 'samtools_flagstat.sh'

    stub:
    """
    touch ${S_NAME}_samtools_flagstat_${PROCESSOR}.txt
    """
}