/*
 * deepvariant: GPU-accelerated deep-learning germline variant caller.
 *
 * NOTE: confirm exact flag names (esp. --mode options and the output
 * flag) against `pbrun deepvariant --help` for the Parabricks version
 * pinned in params.parabricks_container.
 *
 * Exome support: --interval-file + --use-wes-model (shortread mode only) when
 * sequencing_type == 'wes', see EXOME_PROCESSING_SPECS_DEV.md.
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
    path interval_file   // NO_FILE_INTERVAL placeholder when sequencing_type == 'wgs'
    val  use_wes_model   // true when sequencing_type == 'wes' and deepvariant_mode == 'shortread'

    output:
    tuple val(sample_id), val('deepvariant'), path("${sample_id}.deepvariant.vcf"),  emit: vcf

    script:
    def interval_arg  = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    def wes_model_arg = use_wes_model ? '--use-wes-model' : ''
    """
    pbrun deepvariant \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        --mode ${params.deepvariant_mode} \\
        --out-variants ${sample_id}.deepvariant.vcf \\
        ${interval_arg} \\
        ${wes_model_arg} \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
