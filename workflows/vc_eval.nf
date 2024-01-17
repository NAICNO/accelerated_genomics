#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

include { eval_concordance                } from './modules/eval_modules/eval_concordance'
include { bed_intersect                   } from './modules/eval_modules/bed_intersect'
include { eval_hc_filt as hc_filter_cpu   } from './modules/eval_modules/eval_hc_filt'
include { eval_hc_filt as hc_filter_gpu   } from './modules/eval_modules/eval_hc_filt'
include { eval_vc_filt as vc_filter_cpu   } from './modules/eval_modules/eval_vc_filt'
include { eval_vc_filt as vc_filter_gpu   } from './modules/eval_modules/eval_vc_filt'
include { eval_vc_matrix as vc_matrix_cpu } from './modules/eval_modules/eval_vc_matrix'
include { eval_vc_matrix as vc_matrix_gpu } from './modules/eval_modules/eval_vc_matrix'


def PROCESSOR = "CPU"
params.skip_HCfilt = false // Default is not to skip


// Function which prints help message
def helpMessage() {
    log.info"""
Usage:
  --help                Print this help message

  Input Data:
  --sample_name         Sample name to be used in the output file names
  --VC_GPU              GPU variant call-set
  --VC_CPU              CPU variant call-set

  Reference Data:
  --genome_folder       Folder containing reference genome and other reference files
  --genome_json         JSON file listing reference files available in --genome_folder
                        (Use reference_data.josn provided in this pipeline or follow the same format)

  Region files:
  --target_regions      Genomic regions targeted by the assay/exome capture kit
  --diff_map_regions    Union of all difficult to map regions and all segmental duplications released by PrecisionFDA Truth Challenge V2
  --functional_regions  Functional/coding regions released by PrecisionFDA Truth Challenge V2

  Optional parameters:
  --skip_HCfilt         Skip hard filtering of variants (Default: false)

    """.stripIndent()
}


workflow {

    main:

    if ( params.help ){
        helpMessage()
        exit 1
    }

    def reference_map = JsonProcessor.processInputJson(params.genome_json)

    VC_CPU = Channel.fromPath(params.VC_CPU)
    VC_GPU = Channel.fromPath(params.VC_GPU)
    VC_DB = Channel.fromPath(params.vc_db)
    genome_folder = Channel.fromPath(params.genome_folder)
    S_NAME = Channel.from(params.sample_name)
    TARGET_REGIONS = file(params.target_regions)
    DIFFMAP_REGIONS = file(params.diff_map_regions)
    FUNC_REGIONS = file(params.functional_regions)
    
    params.skip_HCfilt 
        ? vc_filter_cpu(S_NAME, VC_CPU, PROCESSOR)
        : hc_filter_cpu(S_NAME, VC_CPU, PROCESSOR)
    
    vc_cpu_pass = params.skip_HCfilt 
        ? vc_filter_cpu.out.vc_pass 
        : hc_filter_cpu.out.hc_filt_pass
    
    params.skip_HCfilt 
        ? vc_filter_gpu(S_NAME, VC_GPU, PROCESSOR) 
        : hc_filter_gpu(S_NAME, VC_GPU, PROCESSOR)

    vc_gpu_pass = params.skip_HCfilt 
        ? vc_filter_gpu.out.vc_pass 
        : hc_filter_gpu.out.hc_filt_pass

    // Creating tuples for each comparison
    def dummyFile = file("EMPTY_FILE")
    intersect_ch = Channel.of(
        ['DIFF2MAP_REGIONS', DIFFMAP_REGIONS],
        ['FUNCTIONAL_REGIONS', FUNC_REGIONS],
        ['TARGET_REGIONS', dummyFile]
    )

    intersect_ch.map { type, bed -> tuple(S_NAME, type, TARGET_REGIONS, bed) }
        .set { intersect_params }

    // Store the output in a new channel
    intersect_params.set { bed_intersect_ch }
    bed_intersect(bed_intersect_ch)
    bed_intersect_out = bed_intersect.out.intersect
    bed_files = bed_intersect_out.collect().flatten()

    Channel
        .from(params.sample_name)
        .combine(vc_cpu_pass)
        .combine(vc_gpu_pass)
        .combine(bed_files)
        .set{genotype_concordance_params}

    eval_concordance(genotype_concordance_params)


    // tuple val(S_NAME), path(VCF), path(DBSNP), path(TARGET_REGIONS), path(REF), val(REF_MAP)
    vc_matrix_cpu(S_NAME, vc_cpu_pass, VC_DB, TARGET_REGIONS, genome_folder, reference_map)
    vc_matrix_gpu(S_NAME, vc_gpu_pass, VC_DB, TARGET_REGIONS, genome_folder, reference_map)
}