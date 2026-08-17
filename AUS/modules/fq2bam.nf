/*
 * fq2bam: GPU-accelerated alignment, sorting, and duplicate marking.
 * Runs once per item on the input channel -- called with a channel that
 * carries one tumor and one normal FASTQ pair, so this single process
 * definition produces both BAMs.
 *
 * NOTE: flags below reflect the general `pbrun fq2bam` CLI pattern.
 * Confirm exact flag names/order against `pbrun fq2bam --help` for the
 * Parabricks version pinned in params.parabricks_container.
 */

process FQ2BAM {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    publishDir { "${params.outdir}/bam/${sample_id}" }, mode: 'copy', pattern: "*.bam*"

    input:
    tuple val(sample_id), val(sample_type), path(fastq_1), path(fastq_2)
    path ref
    path ref_index
    path ref_dict

    output:
    tuple val(sample_id), val(sample_type), path("${sample_id}.bam"), path("${sample_id}.bam.bai"), emit: bam

    script:
    """
    pbrun fq2bam \\
        --ref ${ref} \\
        --in-fq ${fastq_1} ${fastq_2} \\
        --out-bam ${sample_id}.bam \\
        --num-gpus ${task.accelerator?.request ?: 1} \\
        --tmp-dir ./pbrun_tmp
    """
}
