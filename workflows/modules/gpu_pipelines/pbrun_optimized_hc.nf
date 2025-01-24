#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Process to run GATK HaplotypeCaller on a split BAM files
process optimized_hc {
    tag "chr${chr}"
    publishDir "${params.outdir}/vcfs", mode: 'copy'
    
    input:
    tuple val(chr), path(bam), path(bam_index)
    each path(fasta)
    each path(fasta_index)
    each path(fasta_dict)

    output:
    tuple path("${bam.baseName}.vcf"), path("${bam.baseName}.log") 

    script:
    // Calculate paired GPU devices based on task index
    // With 8 GPUs total, we can run 4 concurrent processes (2 GPUs each)
    def start_gpu = (task.index % 4) * 2  // (task.index % 4) * 2 = 0 * 2, 1 * 2, 2 * 2, 3 * 2 = 0, 2, 4, 6
    def gpu_pair = "${start_gpu},${start_gpu + 1}"  // Pairs will be 0,1 or 2,3 or 4,5 or 6,7

    """
    echo "Start time: \$(date)" > ${bam.baseName}.log

    export CUDA_VISIBLE_DEVICES=${gpu_pair}

    pbrun haplotypecaller \
        --ref ${fasta} \
        --num-gpus 2 \
        --in-bam ${bam} \
        --out-variants  ${bam.baseName}.vcf

    echo "End time: \$(date)" >> ${bam.baseName}.log
    """
}