/*
 * applybqsr: GPU-accelerated application of the BQSR recalibration table,
 * producing the analysis-ready BAM used by the downstream callers.
 *
 * NOTE: confirm exact flag names against `pbrun applybqsr --help` for the
 * Parabricks version pinned in params.parabricks_container.
 *
 * Exome support: restricted to target regions via --interval-file when
 * sequencing_type == 'wes' (params.interval_file)
 */

process APPLYBQSR {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    publishDir { "${params.outdir}/bam_recal/${sample_id}" }, mode: 'copy', pattern: "*.bam*"

    input:
    tuple val(sample_id), val(sample_type), path(bam), path(bai), path(recal_table)
    path ref
    path ref_index
    path ref_dict
    path interval_file   // NO_FILE_INTERVAL placeholder when sequencing_type == 'wgs'

    output:
    tuple val(sample_id), val(sample_type), path("${sample_id}.recal.bam"), path("${sample_id}.recal.bam.bai"), emit: bam

    script:
    def interval_arg = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    
    """
    pbrun applybqsr \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        --in-recal-file ${recal_table} \\
        --out-bam ${sample_id}.recal.bam \\
        ${interval_arg} \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
