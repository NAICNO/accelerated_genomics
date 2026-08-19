#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

// process isec_vcf {
//     container '/home/pubuduss/singularity_images/bedtools_v2.31.1--hf5e1c6e_0.sif'
//     errorStrategy 'ignore'
//
//     input:
//     tuple path(vcf),  path(compare_bed), val(S_NAME)
//
//     output:
//     path("*intersect*"), emit: intersect_vcf
//
//     script:
//     """
//     bedtools intersect -a ${vcf} -b ${compare_bed} > ${vcf}.intersect.${compare_bed}
//     """
// }


include { intersect_vcf  as intersect_vcf_a } from './isec_vcf'
include { intersect_vcf  as intersect_vcf_b } from './isec_vcf'

def PROCESSOR = "CPU"

process eval_intersect {
    container '/home/pubuduss/singularity_images/bedtools_v2.31.1--hf5e1c6e_0.sif'
    tag "Intersect with ${type}"

    input:
    tuple val(S_NAME), path(source_bed), val(PROCESSOR), val(type), path(compare_bed)

    output:
    path("*${type}.bed"), emit: intersect

    script:
    def output_filename = "${source_bed.baseName}.${type}.bed"
    """
    if [ -f ${compare_bed} ]; then
        bedtools intersect -a $source_bed -b $compare_bed > $output_filename
    else
        cp $source_bed $output_filename
    fi
    """
}

workflow {

    S_NAME = Channel.from(params.sample_name)
    TARGET_REGIONS = file(params.target_regions)
    DIFFMAP_REGIONS = file(params.diff_map_regions)
    FUNC_REGIONS = file(params.functional_regions)
    VCF = file(params.vcf)
    VCF2 = file(params.vcf2)

    // Creating tuples for each comparison
    def dummyFile = file("EMPTY_FILE")
    compare_ch = Channel.of(
        ['DIFF2MAP_REGIONS', DIFFMAP_REGIONS],
        ['FUNCTIONAL_REGIONS', FUNC_REGIONS],
        ['TARGET_REGIONS', dummyFile]
    )

    compare_ch.map { type, bed -> tuple(S_NAME, TARGET_REGIONS, PROCESSOR, type, bed) }
        .set { intersect_params }

    // Store the output in a new channel
    intersect_params.set { eval_intersect_ch }
    eval_intersect(eval_intersect_ch)
    eval_intersect_out = eval_intersect.out.intersect

    eval_intersect_out.view { file ->
        println "Emitted file: $file"
    }

    all_files = eval_intersect_out.collect().flatten()
    //Channel.fromPath(VCF).combine(all_files).set{intersect_params}
    Channel
        .fromPath(VCF)
        .combine(all_files)
        .combine(S_NAME)
        .set{intersect_params}
    Channel
        .fromPath(VCF2)
        .combine(all_files)
        .combine(S_NAME)
        .set{intersect_params_2}

    // Run the intersect_vcf process
    intersect_vcf_a(intersect_params)
    intersect_vcf_b(intersect_params_2)

}