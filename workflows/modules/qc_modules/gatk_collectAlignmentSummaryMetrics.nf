#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process gatk_collectAlignmentSummaryMetrics {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/AlignmentSummaryMetrics", mode: 'symlink', overwrite: true
    
    input:
    val(S_NAME)
    path(BAM)
    path(BAI)
    path(REF)
    val(REF_MAP)
    val(PROCESSOR)

    output:
    path("${BAM}.alignment_summary_metrics.txt")

    script:
    template 'gatk_collectAlignmentSummaryMetrics.sh'

    stub:
    """
    touch ${BAM}.alignment_summary_metrics.txt
    sleep 5
    """

}

