#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process bed_intersect {
    publishDir "Results/CPUvsGPU/${S_NAME}/regions", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), val(TYPE), path(SOURCE), path(QUERY), path(REF), val(REF_MAP)

    output:
    path("*${TYPE}*")
    path("*intervals_list"), emit: intersect

    script:
    template 'bed_intersect.sh'
}
