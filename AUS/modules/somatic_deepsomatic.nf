/*
 * deepsomatic: GPU-accelerated deep-learning somatic variant calling,
 * standalone branch (tumor+normal BAM in, DeepSomatic VCF out).
 *
 * NOTE: confirm exact flag names (esp. --model-type options and the
 * output flag) against `pbrun deepsomatic --help` for the Parabricks
 * version pinned in params.parabricks_container -- DeepSomatic support
 * was added relatively recently and flags may differ across versions.
 */

process DEEPSOMATIC {
    tag "${tumor_id}_vs_${normal_id}"
    label 'gpu_process'
    container params.parabricks_container

    publishDir "${params.outdir}/vcf/deepsomatic", mode: 'copy'

    input:
    tuple val(tumor_id), path(tumor_bam), path(tumor_bai)
    tuple val(normal_id), path(normal_bam), path(normal_bai)
    path ref
    path ref_index
    path ref_dict

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.deepsomatic.vcf"),  emit: vcf

    script:
    """
    pbrun deepsomatic \\
        --ref ${ref} \\
        --in-tumor-bam ${tumor_bam} \\
        --in-normal-bam ${normal_bam} \\
        --out-variants ${tumor_id}_vs_${normal_id}.deepsomatic.vcf \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}