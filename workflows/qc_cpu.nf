#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field


include { samtools_flagstat                    } from './modules/qc_modules/samtools_flagstat'
include { mosdepth                             } from './modules/qc_modules/mosdepth'
include { gatk_collectInsertSizeMetrics        } from './modules/qc_modules/gatk_collectInsertSizeMetrics'
include { gatk_collectAlignmentSummaryMetrics  } from './modules/qc_modules/gatk_collectAlignmentSummaryMetrics'

def PROCESSOR = "CPU"

// Function which prints help message
def helpMessage() {
    log.info"""
Usage:

  Input Data:
  --fastq_folder        Folder containing paired-end FASTQ files ending with .fastq.gz,
                        containing either "_R1" or "_R2" in the filename.
  --bam_path            Path to BAM file
  --bai_path            Path to BAI file

  Reference Data:
  --genome_folder       Folder containing reference genome and other reference files
  --genome_json         JSON file listing reference files available in --genome_folder
                        (Use reference_data.josn provided in this pipeline or follow the same format)

    """.stripIndent()
}

workflow {

    // Define the pattern which will be used to find the FASTQ files

    main:

    // Check if the required parameters are provided
    // if ( params.help || params.fastq_folder == false || params.genome_folder == false  || params.genome_json == false){
    //     helpMessage()
    //     exit 1
    // }

    def reference_map = JsonProcessor.processInputJson(params.genome_json)

    fastq_pattern = "${params.fastq_folder}/*_R{1,2}*fastq.gz"
    input_fqs = Channel
        .fromFilePairs(fastq_pattern)
        .ifEmpty { error "No files found matching the pattern ${fastq_pattern}" }
        .map{
            [it[0], it[1][0], it[1][1]]
        }
    

    // Set sample_name to the first FASTQ file name
    // input_fqs
    //     .map { it[0] }
    //     .first()
    //     .set { sample_name }

    // Create a tuple with sample_name, bam_path, and bai_path
    // bam_bai = tuple(sample_name.get(), params.bam_path, params.bai_path)

    def sample_name = "test"
    bam_bai = tuple(sample_name, params.bam_path, params.bai_path)

    samtools_flagstat (
        sample_name,
        bam_bai,
        PROCESSOR
    )

    mosdepth(
        bam_bai, genome_folder, reference_map, PROCESSOR
    )

    gatk_collectInsertSizeMetrics(
        bam_bai, PROCESSOR
    )

    gatk_collectAlignmentSummaryMetrics(
        bam_bai, genome_folder, reference_map, PROCESSOR
    )

}
