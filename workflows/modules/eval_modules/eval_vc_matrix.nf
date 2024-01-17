#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_vc_matrix {
    publishDir "Results/CPUvsGPU/${S_NAME}/variants/metrics", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(VCF)
    path(DBSNP)
    path(TARGET_REGIONS)
    path(REF)
    val(REF_MAP)

    output:
    path("VCMetrics_*")

    script:
    template 'eval_vc_matrix.sh'
}
