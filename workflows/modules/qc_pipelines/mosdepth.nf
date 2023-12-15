#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process mosdepth {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/mosdepth", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("mosdepth*"), emit: mosdepth

    script:
    template 'mosdepth.sh'

}

