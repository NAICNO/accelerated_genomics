/*
 * haplotypecaller: GPU-accelerated germline variant calling
 * (GPU port of GATK4 HaplotypeCaller).
 *
 * NOTE: confirm exact flag names (esp. the output flag and whether
 * --gvcf is the correct switch for GVCF mode) against
 * `pbrun haplotypecaller --help` for the Parabricks version pinned
 * in params.parabricks_container.
 */

process HAPLOTYPECALLER {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    publishDir "${params.outdir}/vcf/haplotypecaller", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref
    path ref_index
    path ref_dict

    output:
    tuple val(sample_id), val('haplotypecaller'), path("${sample_id}.haplotypecaller.vcf.gz"), path("${sample_id}.haplotypecaller.vcf.gz.tbi"), emit: vcf

    script:
    def gvcf_arg = params.emit_gvcf ? '--gvcf' : ''
    """
    pbrun haplotypecaller \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        ${gvcf_arg} \\
        --out-variants ${sample_id}.haplotypecaller.vcf.gz \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
