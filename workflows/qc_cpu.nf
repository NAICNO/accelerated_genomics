#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

include { fastqc                               } from './modules/qc_modules/fastqc'
include { samtools_flagstat                    } from './modules/qc_modules/samtools_flagstat'
include { mosdepth                             } from './modules/qc_modules/mosdepth'
include { gatk_collectInsertSizeMetrics        } from './modules/qc_modules/gatk_collectInsertSizeMetrics'
include { gatk_collectAlignmentSummaryMetrics  } from './modules/qc_modules/gatk_collectAlignmentSummaryMetrics'
include { multiqc                              } from './modules/qc_modules/multiqc'

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
  --sample_name         Sample name to be used in the output file names

  Reference Data:
  --genome_folder       Folder containing reference genome and other reference files
  --genome_json         JSON file listing reference files available in --genome_folder
                        (Use reference_data.josn provided in this pipeline or follow the same format)

    """.stripIndent()
}

workflow {

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
    
    BAM_FILE = Channel.fromPath(params.bam_path)
    BAI_FILE = Channel.fromPath(params.bai_path)
    genome_folder = Channel.fromPath(params.genome_folder)
    S_NAME = Channel.from(params.sample_name)
    //bam_bai = tuple(BAM_FILE, BAI_FILE)

    fastqc(input_fqs, PROCESSOR)

    samtools_flagstat (
        BAM_FILE, 
        BAI_FILE,
        PROCESSOR,
        S_NAME
    )

    mosdepth(
        S_NAME, BAM_FILE, BAI_FILE, genome_folder, reference_map, PROCESSOR
    )

    gatk_collectInsertSizeMetrics(
        S_NAME, BAM_FILE, BAI_FILE, PROCESSOR
    )

    gatk_collectAlignmentSummaryMetrics(
        S_NAME, BAM_FILE, BAI_FILE, genome_folder, reference_map, PROCESSOR
    )

    multiqc(
        S_NAME,
        PROCESSOR,
        fastqc.out.collect(), 
        samtools_flagstat.out.collect(), 
        mosdepth.out.collect(), 
        gatk_collectInsertSizeMetrics.out.collect(), 
        gatk_collectAlignmentSummaryMetrics.out.collect()
    )


}
