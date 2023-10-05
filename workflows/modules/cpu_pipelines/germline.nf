#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
def PROCESSOR = "CPU"

process bwa {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(R1), path(R2)
    path REF
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_bwa-mem_${PROCESSOR}.sam"), emit: sam

    script:
    template 'bwa_mapping.sh'

}

process gatk_sort {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(SAM)

    output:
    tuple val(S_NAME), path("${SAM}.bam"), emit: sort_bam

    script:
    template 'gatk_sort_coordinate.sh'

}

process gatk_mark_dup {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM)

    output:
    tuple val(S_NAME), path("${BAM}_markdup.bam"), emit: markdup_bam

    script:
    template 'gatk_mark_dup.sh'

}

process gatk_bqsr {
    publishDir "Results/${PROCESSOR}/${S_NAME}/metadata/gatk/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM)
    path REF
    val(PROCESSOR)

    output:
    tuple val(S_NAME), path("${S_NAME}_${PROCESSOR}_recal.txt"), emit: bqsr

    script:
    template 'gatk_bqsr.sh'

}

process gatk_apply_bqsr {
    publishDir "Results/${PROCESSOR}/${S_NAME}/alignments/", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(RECAL)
    tuple val(S_NAME), path(BAM)
    path REF

    output:
    tuple val(S_NAME), path("${BAM}_BQSR.bam"), emit: apply_bqsr

    script:
    template 'gatk_apply_bqsr.sh'

}

process gatk_haplotypeCaller {
    publishDir "Results/${PROCESSOR}/${S_NAME}/variants/haplotypeCaller", mode: 'copy', overwrite: true
    
    input:
    tuple val(S_NAME), path(BAM)
    path REF

    output:
    tuple val(S_NAME), path("${BAM}.vcf"), emit: haplotypeCaller

    script:
    template 'gatk_haplotype.sh'

}

workflow germline{

    take:
    input_fqs
    genome_folder

    main:


    // BWA mapping
    bwa(
        input_fqs, genome_folder, PROCESSOR
    )

    // GATK sort by coordinate
    gatk_sort(bwa.out.sam)

    // GATK MarkDuplicates
    gatk_mark_dup(gatk_sort.out.sort_bam)

    // GATK BaseRecalibrator
    gatk_bqsr(gatk_mark_dup.out.markdup_bam, genome_folder, PROCESSOR)

    // GATK ApplyBQSR
    gatk_apply_bqsr(gatk_bqsr.out.bqsr, gatk_mark_dup.out.markdup_bam, genome_folder)

    // GATK HaplotypeCaller
    gatk_haplotypeCaller(gatk_apply_bqsr.out.apply_bqsr, genome_folder)

}