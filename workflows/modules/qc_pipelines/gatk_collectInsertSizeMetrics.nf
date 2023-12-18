#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_collectInsertSizeMetrics {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/InsertSizeMetrics", mode: 'symlink', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM), path(BAI)
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${BAM}.insert_size_metrics.txt"), emit: insertsizemetrics

    script:
    template 'gatk_collectInsertSizeMetrics.sh'

}
