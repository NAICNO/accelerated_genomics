#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_concordance {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/evaluation/GenotypeConcordance", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(VCF)
    path(QUERY_VCF)
    path(TARGET_REGIONS)
    val(PROCESSOR)

    output:
    path("VC_*")

    script:
    template 'eval_concordance.sh'
}

