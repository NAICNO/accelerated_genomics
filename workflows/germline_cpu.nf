#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// All of the default parameters are being set in `nextflow.config`

// Import sub-workflows
include { germline } from './modules/cpu_pipelines/germline.nf'


// Function which prints help message
def helpMessage() {
    log.info"""
Usage:

  Input Data:
  --fastq_folder        Folder containing paired-end FASTQ files ending with .fastq.gz,
                        containing either "_R1" or "_R2" in the filename.

  Reference Data:
  --genome_folder        Folder containing reference genome and other reference files

    """.stripIndent()
}


workflow {

    // Print help message if input is invalid or input is "help" 
    if ( params.help || params.fastq_folder == false || params.genome_folder == false ){
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

    // Define the pattern which will be used to find the FASTQ files

    fastq_pattern = "${params.fastq_folder}/*_R{1,2}*fastq.gz"
    input_fqs = Channel
        .fromFilePairs(fastq_pattern)
        .ifEmpty { error "No files found matching the pattern ${fastq_pattern}" }
        .map{
            [it[0], it[1][0], it[1][1]]
        }

    genome_folder = Channel.fromPath( params.genome_folder )

    germline(
        input_fqs, genome_folder
    )

}