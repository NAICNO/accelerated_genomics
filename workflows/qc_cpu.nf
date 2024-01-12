#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
import groovy.json.JsonSlurper
import groovy.transform.Field

include { fastqc                               } from './modules/qc_modules/fastqc'
include { samtools_flagstat                    } from './modules/qc_modules/samtools_flagstat'
include { samtools_stat                        } from './modules/qc_modules/samtools_stat'
include { mosdepth                             } from './modules/qc_modules/mosdepth'
include { gatk_collectInsertSizeMetrics        } from './modules/qc_modules/gatk_collectInsertSizeMetrics'
include { gatk_collectAlignmentSummaryMetrics  } from './modules/qc_modules/gatk_collectAlignmentSummaryMetrics'
include { multiqc                              } from './modules/qc_modules/multiqc'

def PROCESSOR = "CPU"
params.skip_fastqc = false // Default is not to skip


// Function which prints help message
def helpMessage() {
    log.info"""
Usage:
  --help                Print this help message

  Input Data:
  --sample_name         Sample name to be used in the output file names
  --fastq_R1            Read 1 of .fastq.gz file
  --fastq_R2            Read 2 of .fastq.gz file
  --bam_path            Path to BAM file
  --bai_path            Path to BAI file
  

  Reference Data:
  --genome_folder       Folder containing reference genome and other reference files
  --genome_json         JSON file listing reference files available in --genome_folder
                        (Use reference_data.josn provided in this pipeline or follow the same format)

  Optional parameters:
  --target_regions      Genomic regions targeted by the assay/exome capture kit

    """.stripIndent()
}

workflow {

    main:

    def reference_map = JsonProcessor.processInputJson(params.genome_json)

    R1 = params.fastq_R1 ? Channel.fromPath(params.fastq_R1, checkIfExists: true) : Channel.empty()
    R2 = params.fastq_R2 ? Channel.fromPath(params.fastq_R2, checkIfExists: true) : Channel.empty()
    BAM_FILE = Channel.fromPath(params.bam_path)
    BAI_FILE = Channel.fromPath(params.bai_path)
    genome_folder = Channel.fromPath(params.genome_folder)
    S_NAME = Channel.from(params.sample_name)
    TARGET_REGIONS = params.target_regions ? Channel.fromPath(params.target_regions, checkIfExists: true) : Channel.empty()

    fastqc(R1, R2, S_NAME, PROCESSOR)

    samtools_flagstat (
        BAM_FILE, 
        BAI_FILE,
        PROCESSOR,
        S_NAME
    )

    samtools_stat (
        BAM_FILE, 
        BAI_FILE,
        PROCESSOR,
        S_NAME
    )

    mosdepth(
        S_NAME, BAM_FILE, BAI_FILE, genome_folder, reference_map, TARGET_REGIONS, PROCESSOR
    )

    gatk_collectInsertSizeMetrics(
        S_NAME, BAM_FILE, BAI_FILE, genome_folder, reference_map, PROCESSOR
    )

    gatk_collectAlignmentSummaryMetrics(
        S_NAME, BAM_FILE, BAI_FILE, genome_folder, reference_map, PROCESSOR
    )

    multiqc(
        S_NAME,
        PROCESSOR,
        fastqc.out.collect().ifEmpty([]), 
        samtools_flagstat.out.collect(), 
        samtools_stat.out.collect(), 
        mosdepth.out.collect(), 
        gatk_collectInsertSizeMetrics.out.collect(), 
        gatk_collectAlignmentSummaryMetrics.out.collect()
    )


}
