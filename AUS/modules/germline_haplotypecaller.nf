/*
 * haplotypecaller: GPU-accelerated germline variant calling
 * (GPU port of GATK4 HaplotypeCaller).
 *
 * NOTE: confirm exact flag names (esp. whether --gvcf is the correct
 * switch for GVCF mode) against `pbrun haplotypecaller --help` for the
 * Parabricks version pinned in params.parabricks_container.
 *
 * Output must be a plain, uncompressed .vcf: `pbrun haplotypecaller`'s
 * htvc binary rejects a .vcf.gz output name outright ("Output file name
 * should be .vcf", exit 1) -- unlike deepvariant, which accepts
 * .vcf.gz. GATK-style tools index a plain .vcf with a .vcf.idx sidecar
 * rather than a bgzip .tbi, so the emitted index follows suit; confirm
 * htvc actually writes that .idx file for this Parabricks version.
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
    tuple val(sample_id), val('haplotypecaller'), path("${sample_id}.haplotypecaller.vcf"),  emit: vcf

    script:
    def gvcf_arg = params.emit_gvcf ? '--gvcf' : ''
    """
    pbrun haplotypecaller \\
        --ref ${ref} \\
        --in-bam ${bam} \\
        ${gvcf_arg} \\
        --out-variants ${sample_id}.haplotypecaller.vcf \\
        --num-gpus ${task.accelerator?.request ?: 1}
    """
}
