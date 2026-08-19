#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Default parameters
params.bam = null
params.fasta = null
params.outdir = 'Results'
params.chromosomes = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 
                     '11', '12', '13', '14', '15', '16', '17', '18', '19', 
                     '20', '21', '22', 'X', 'Y']

// Import sub-workflows
include { optimized_hc            } from './modules/gpu_pipelines/pbrun_optimized_hc'
include { split_bam_by_chromosome } from './modules/cpu_pipelines/samtools_split_bam'

workflow {
    // Input channels
    bam_ch = channel.fromPath(params.bam)
    bai_ch = channel.fromPath(params.bai)
    fasta_ch = channel.fromPath(params.fasta)
    fasta_index_ch = channel.fromPath("${params.fasta}.fai")
    fasta_dict_ch = channel.fromPath("${params.fasta.replaceAll(/\.fa(sta)?$/, '')}.dict")

    // Create a channel combining chromosomes with the input BAM
    chr_bam_ch = channel
        .fromList(params.chromosomes)
        .combine(bam_ch)
        .combine(bai_ch)

    // Split BAM by chromosome (runs in parallel)
    split_bams = split_bam_by_chromosome(chr_bam_ch)
        .split_bams
        .map { chr, bam, bai -> tuple(chr, bam, bai) }

    // Run HaplotypeCaller on each split BAM (runs in parallel)
    optimized_hc(
        split_bams,
        fasta_ch,
        fasta_index_ch,
        fasta_dict_ch
    )

}
