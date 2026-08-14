/*
 * bqsr: GPU-accelerated base quality score recalibration table generation.
 * Runs on both the tumor and normal BAM (same process, tagged channel).
 *
 * NOTE: confirm exact flag names against `pbrun bqsr --help` for the
 * Parabricks version pinned in params.parabricks_container.
 */

process BQSR {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    input:
    tuple val(sample_id), val(sample_type), path(bam), path(bai)
    path ref
    path ref_index
    path ref_dict
    path known_sites_vcfs
    path known_sites_tbis

    output:
    tuple val(sample_id), val(sample_type), path(bam), path(bai), path("${sample_id}.recal.table"), emit: recal

    script:
    def known_sites_args = known_sites_vcfs.collect { "--knownSites ${it}" }.join(' ')
    """
    pbrun bqsr \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        ${known_sites_args} \\
        --out-recal-file ${sample_id}.recal.table \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
