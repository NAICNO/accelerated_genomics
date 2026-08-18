/*
 * mutectcaller: GPU-accelerated somatic variant calling (Mutect2 algorithm).
 * Emits both the raw VCF (consumed directly by vcfqc) and the caller stats
 * file (consumed by postpon/FilterMutectCalls).
 *
 * NOTE: confirm exact flag names against `pbrun mutectcaller --help` for
 * the Parabricks version pinned in params.parabricks_container.
 */

process MUTECTCALLER {
    tag "${tumor_id}_vs_${normal_id}"
    label 'gpu_process'
    container params.parabricks_container

    input:
    tuple val(tumor_id), path(tumor_bam), path(tumor_bai)
    tuple val(normal_id), path(normal_bam), path(normal_bai)
    path ref
    path ref_index
    path ref_dict
    path pon
    path pon_index

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.mutect2.vcf.gz"), path("${tumor_id}_vs_${normal_id}.mutect2.vcf.gz.tbi"), path("${tumor_id}_vs_${normal_id}.mutect2.vcf.gz.stats"), emit: vcf

    script:
    def pon_arg = pon.name.startsWith('NO_FILE') ? '' : "--pon ${pon}"
    """
    pbrun mutectcaller \\
        --ref ${ref} \\
        --in-tumor-bam ${tumor_bam} \\
        --tumor-name ${tumor_id} \\
	    --normal-name ${normal_id} \\
        --in-normal-bam ${normal_bam} \\
        ${pon_arg} \\
        --out-vcf ${tumor_id}_vs_${normal_id}.mutect2.vcf.gz \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
