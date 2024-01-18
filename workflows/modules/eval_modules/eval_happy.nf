#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_happy {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/evaluation/hap_py", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(VCF)
    path(QUERY_VCF)
    path(TARGET_REGIONS)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    path("VC_*")

    script:
    template 'eval_happy.sh'
}

