#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process samtools_flagstat {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    path(BAM)
    path(BAI)
    val(PROCESSOR)

    output:
    path("${BAM}_samtools_flagstat_${PROCESSOR}.txt"), emit: flagstat

    script:
    template 'samtools_flagstat.sh'

    stub:
    """
    touch ${BAM}_samtools_flagstat_${PROCESSOR}.txt
    """
}