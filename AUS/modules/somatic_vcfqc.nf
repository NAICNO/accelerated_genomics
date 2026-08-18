/*
 * vcfqc: QC on the raw Mutect2 VCF (branches directly off mutectcaller,
 * in parallel with postpon -- see diagram in somatic.config). CPU,
 * lightweight bcftools stats report.
 */

process VCFQC {
    tag "${tumor_id}_vs_${normal_id}"
    label 'leaf_process'
    container params.bcftools_container

    publishDir "${params.outdir}/qc/vcf", mode: 'copy'

    input:
    tuple val(tumor_id), val(normal_id), path(vcf), path(vcf_index), path(stats)

    output:
    path "${tumor_id}_vs_${normal_id}.vcf_stats.txt"

    script:
    """
    bcftools stats ${vcf} > ${tumor_id}_vs_${normal_id}.vcf_stats.txt
    """
}
