#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Process to split BAM by chromosome - now parallelized
process split_bam_by_chromosome {
    tag "chr${chromosome}"
    
    input:
    tuple val(chromosome), path(bam), path(bai)

    output:
    tuple val(chromosome), path("chr${chromosome}.bam"), path("chr${chromosome}.bam.bai"), emit: split_bams

    script:
    """
    samtools view -@${task.cpus} -b ${bam} chr${chromosome} > chr${chromosome}.bam
    samtools index -@${task.cpus} -b  chr${chromosome}.bam
    """
}