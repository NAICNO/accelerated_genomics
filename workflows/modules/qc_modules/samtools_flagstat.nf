#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process samtools_flagstat {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/flagstat/", mode: 'symlink', overwrite: true
    
    input:
    path(BAM)
    path(BAI)
    val(PROCESSOR)
    val(S_NAME)

    output:
    path("${BAM}_samtools_flagstat_${PROCESSOR}.txt")

    script:
    template 'samtools_flagstat.sh'
}