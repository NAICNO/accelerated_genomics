#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process multiqc {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/multiqc", mode: 'symlink', overwrite: true

    input:
    val(S_NAME)
    val(PROCESSOR)
    path(fastqc)
    path(samtools_flagstat)
    path(mosdepth)
    path(gatk_collectInsertSizeMetrics)
    path(gatk_collectAlignmentSummaryMetrics)

    output:
    file "multiqc_report.html"
    file "multiqc_data"
    
    script:
    """
    multiqc .
    """

    stub:
    """
    ls -l > multiqc_report.html
    """

}
