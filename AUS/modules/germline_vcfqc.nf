/*
 * vcfqc: QC on a caller's VCF -- one process definition handles both
 * deepvariant and haplotypecaller output, fed via a channel .mix() in
 * germline_workflow.nf (same "one process, tagged channel" pattern as
 * fq2bam handling tumor+normal in the somatic workflow). CPU,
 * lightweight bcftools stats report.
 *
 * `vcf`/`vcf_index` are generic path inputs, so this works unchanged
 * whether the upstream caller emits bgzipped .vcf.gz + .tbi
 * (deepvariant) or plain .vcf + .vcf.idx (haplotypecaller -- pbrun
 * haplotypecaller's htvc binary rejects a .vcf.gz output name).
 * bcftools stats reads both compressed and uncompressed VCFs directly.
 */

process VCFQC {
    tag "${sample_id}_${caller}"
    label 'leaf_process'
    container params.bcftools_container

    publishDir { "${params.outdir}/qc/vcf/${caller}" }, mode: 'copy'

    input:
    tuple val(sample_id), val(caller), path(vcf), path(vcf_index)

    output:
    path "${sample_id}.${caller}.vcf_stats.txt"

    script:
    """
    bcftools stats ${vcf} > ${sample_id}.${caller}.vcf_stats.txt
    """
}
