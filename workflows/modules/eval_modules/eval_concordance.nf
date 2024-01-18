#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_concordance {
    publishDir "Results/CPUvsGPU/${S_NAME}/variants/GenotypeConcordance", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(VCF), path(QUERY_VCF), path(TARGET_REGIONS)

    output:
    path("GenotypeConcordance_*")

    script:
    template 'eval_concordance.sh'
}
