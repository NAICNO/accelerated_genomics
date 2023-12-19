#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_collectInsertSizeMetrics {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/InsertSizeMetrics", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(BAM)
    path(BAI)
    val(PROCESSOR)

    output:
    path("${BAM}.insert_size_metrics.txt")
    script:
    template 'gatk_collectInsertSizeMetrics.sh'

    stub:
    """
    touch ${BAM}.insert_size_metrics.txt
    sleep 5
    """

}

