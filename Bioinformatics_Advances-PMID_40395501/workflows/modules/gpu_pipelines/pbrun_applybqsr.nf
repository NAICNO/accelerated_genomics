#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process pbrun_applybqsr {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(RECAL)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)
    path(TARGET_REGIONS)

    output:
    tuple val(S_NAME),  path("${BAM}_applybqsr.bam"), path("${BAM}_applybqsr.bam.bai"), emit: applybqsr


    script:
    template 'pbrun_applybqsr.sh'

}