#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

// All of the default parameters are being set in `nextflow.config`

// Import sub-workflows
//include { germline } from './modules/cpu_pipelines/germline.nf'


// Function which prints help message
def helpMessage() {
    log.info"""
Usage:

  Input Data:
  --fastq_folder        Folder containing paired-end FASTQ files ending with .fastq.gz,
                        containing either "_R1" or "_R2" in the filename.

  Reference Data:
  --genome_folder       Folder containing reference genome and other reference files
  --genome_json         JSON file listing reference files available in --genome_folder
                        (Use reference_data.josn provided in this pipeline or follow the same format)

  Pipeline info:
  --processor           Option to specify the pipeline to run
                        e.g., GPU enabled accelerated NGS pipeline (GPU) or Traditional NGS pipeline (CPU)

    """.stripIndent()
}


workflow workflow_init {

    take:
    params

    main:

    // Print help message if input is invalid or input is "help" 
    if ( params.help || params.fastq_folder == false || params.genome_folder == false  || params.genome_json == false){
        helpMessage()
        exit 1
    }

    // Verify if "fastq_folder" is provides as input
    if ( ! params.fastq_folder || ! params.genome_folder ){
        log.info"""
        Specify --fastq_folder with R1 and R2 fastq files
        Run with --help for more details.
        """.stripIndent()
        // Exit out and do not run anything else
        exit 1
    }

    if ( ! params.genome_json ){
        log.info"""
        Specify --genome_json listing reference files required for the NGS run
        Run with --help for more details.
        """.stripIndent()
        // Exit out and do not run anything else
        exit 1
    }

    if (params.processor != "GPU" && params.processor != "CPU"){
        log.info"""
        Specify GPU or CPU for --processor parameter or
        run with --help for more details.
        """
        println params.processor
        exit 1
    }
}