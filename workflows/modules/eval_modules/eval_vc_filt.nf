#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process eval_vc_filt {
    publishDir "Results/CPUvsGPU/${S_NAME}/variants/vc_filt", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(VCF)
    val(PROCESSOR)

    output:
    path("${VCF}.PASS.vcf"), emit: vc_pass

    script:
    template 'eval_vc_filt.sh'

}
