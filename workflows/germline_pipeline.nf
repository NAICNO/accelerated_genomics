#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

// All of the default parameters are being set in `nextflow.config`

// Import sub-workflows
include { workflow_init } from './modules/nfinit'
include { germline_gpu } from './modules/gpu_pipelines/germline'
include { germline_cpu } from './modules/cpu_pipelines/germline'


workflow {

    // Define the pattern which will be used to find the FASTQ files

    workflow_init(params)

    fastq_pattern = "${params.fastq_folder}/*_R{1,2}*fastq.gz"
    input_fqs = Channel
        .fromFilePairs(fastq_pattern)
        .ifEmpty { error "No files found matching the pattern ${fastq_pattern}" }
        .map{
            [it[0], it[1][0], it[1][1]]
        }

    genome_folder = Channel.fromPath( params.genome_folder )
    def reference_map = JsonProcessor.processInputJson(params.genome_json)

    def dummyFile = file("EMPTY_FILE")
    target_regions = file(params.target_regions).exists() ? Channel.fromPath(params.target_regions) : Channel.fromPath(dummyFile)


    if (params.processor == "GPU"){
        germline_gpu(
            input_fqs, genome_folder, reference_map
        )
    }else{
        germline_cpu(
            input_fqs, fastq_folder, genome_folder, reference_map, target_regions
        )        
    }

}