#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_hc_filt {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/evaluation/hc_filt", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(HC_VCF)
    val(PROCESSOR)

    output:
    path("${HC_VCF}*.vcf")
    path("${HC_VCF}.filtered.PASS.vcf"), emit: eval_hc

    script:
    template 'eval_hc_filt.sh'
}
