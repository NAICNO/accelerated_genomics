#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process pbrun_fq2bam {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(R1), path(R2)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_pbrun_fq2bam_${PROCESSOR}.bam"), path("${S_NAME}_${PROCESSOR}_recal_gpu.txt"), emit: fq2bam

    script:
    template 'pbrun_fq2bam.sh'

}