#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process bwa {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(R1), path(R2)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_bwa-mem_${PROCESSOR}.bam"), path("${S_NAME}_bwa-mem_${PROCESSOR}.bam.bai"), emit: bwa_bam

    script:
    template 'bwa_mapping.sh'

}