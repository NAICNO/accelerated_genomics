#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_vc_matrix {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/evaluation/metrics", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(VCF)
    path(DBSNP)
    path(TARGET_REGIONS)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    path("VC_*")

    script:
    template 'eval_vc_matrix.sh'
}
