/*
 * prepon: pre-panel-of-normals prep for Mutect2 filtering -- pileup
 * summaries + contamination estimation for the tumor/normal pair,
 * feeding FilterMutectCalls in somatic_postpon.nf (CPU, GATK).
 */

process PREPON {
    tag "${tumor_id}_vs_${normal_id}"
    label 'leaf_process'
    container params.gatk_container

    input:
    tuple val(tumor_id), path(tumor_bam), path(tumor_bai)
    tuple val(normal_id), path(normal_bam), path(normal_bai)
    path ref
    path ref_index
    path ref_dict
    path germline_resource
    path germline_resource_index

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}.contamination.table"), path("${tumor_id}.segments.table"), emit: contamination

    script:
    """
    gatk GetPileupSummaries \\
        -I ${tumor_bam} \\
        -V ${germline_resource} \\
        -L ${germline_resource} \\
        -O ${tumor_id}.pileups.table

    gatk GetPileupSummaries \\
        -I ${normal_bam} \\
        -V ${germline_resource} \\
        -L ${germline_resource} \\
        -O ${normal_id}.pileups.table

    gatk CalculateContamination \\
        -I ${tumor_id}.pileups.table \\
        -matched ${normal_id}.pileups.table \\
        -O ${tumor_id}.contamination.table \\
        --tumor-segmentation ${tumor_id}.segments.table
    """
}
