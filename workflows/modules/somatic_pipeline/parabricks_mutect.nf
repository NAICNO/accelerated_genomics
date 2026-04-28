#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process parabricks_mutect {
    publishDir "Results/${PROCESSOR}/${PAIR_ID}/variants/mutect", mode: 'symlink', overwrite: true
    
    input:
    tuple val(PAIR_ID), path(BAM_NORMAL), path(BAI_NORMAL), path(BAM_TUMOR), path(BAI_TUMOR)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)
    path(TARGET_REGIONS)

    output:
    tuple val(PAIR_ID), path("${PAIR_ID}.mutect.vcf"), emit: mutectCaller

    script:
    template 'pbrun_mutectcaller.sh'

}
