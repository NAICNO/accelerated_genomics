/*
 * deepvariant: GPU-accelerated deep-learning germline variant caller.
 *
 * NOTE: confirm exact flag names (esp. --mode options and the output
 * flag) against `pbrun deepvariant --help` for the Parabricks version
 * pinned in params.parabricks_container.
 */

process DEEPVARIANT {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    publishDir "${params.outdir}/vcf/deepvariant", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref
    path ref_index
    path ref_dict

    output:
    tuple val(sample_id), val('deepvariant'), path("${sample_id}.deepvariant.vcf.gz"), path("${sample_id}.deepvariant.vcf.gz.tbi"), emit: vcf

    script:
    """
    pbrun deepvariant \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        --mode ${params.deepvariant_mode} \\
        --out-variants ${sample_id}.deepvariant.vcf.gz \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
