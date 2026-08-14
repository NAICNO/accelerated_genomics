/*
 * postpon: post-panel-of-normals filtering of the raw Mutect2 calls,
 * using the contamination/segmentation tables from somatic_prepon.nf
 * (FilterMutectCalls, CPU, GATK). Produces the final Mutect2 VCF.
 */

process POSTPON {
    tag "${tumor_id}_vs_${normal_id}"
    label 'leaf_process'
    container params.gatk_container

    publishDir "${params.outdir}/vcf/mutect2", mode: 'copy'

    input:
    tuple val(tumor_id), val(normal_id), path(vcf), path(vcf_index), path(stats)
    tuple val(tumor_id2), val(normal_id2), path(contamination_table), path(segments_table)
    path ref
    path ref_index
    path ref_dict

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.mutect2.filtered.vcf.gz"), path("${tumor_id}_vs_${normal_id}.mutect2.filtered.vcf.gz.tbi"), emit: vcf

    script:
    """
    gatk FilterMutectCalls \\
        -R ${ref} \\
        -V ${vcf} \\
        --contamination-table ${contamination_table} \\
        --tumor-segmentation ${segments_table} \\
        -O ${tumor_id}_vs_${normal_id}.mutect2.filtered.vcf.gz
    """
}
