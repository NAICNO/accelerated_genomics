/*
 * pb_postpon: `pbrun postpon` -- Annotate variants based on a PON file and
 * modify the “INFO” field of the input VCF file
 *
 */

process PB_POSTPON {
    tag "${tumor_id}_vs_${normal_id}"
    label 'leaf_process'
    container params.parabricks_container

    input:
    tuple val(tumor_id), val(normal_id), path(vcf), path(vcf_index)
    path pon
    path pon_index

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.mutect2.pon.vcf"), emit: vcf

    script:
    def prefix = "${tumor_id}_vs_${normal_id}"
    """
    gzip -dc ${vcf} > ${prefix}.mutect2.raw.vcf

    pbrun postpon \\
        --in-vcf ${prefix}.mutect2.raw.vcf \\
        --in-pon-file ${pon} \\
        --out-vcf ${prefix}.mutect2.pon.vcf \\
        --tmp-dir ./pbrun_tmp

    rm -f ${prefix}.mutect2.raw.vcf
    """
}

