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

    // Nested by aligner (docs/Giraffe_implementation_specs_dev.md section 5h) so
    // fq2bam and giraffe runs can share one outdir. SHARED with somatic_main.nf,
    // where germline_mapping is never set -- the `?: 'fq2bam'` fallback keeps
    // somatic output at bam/fq2bam/<sample_id>/ instead of bam/null/.
    publishDir { "${params.outdir}/bam/${params.germline_mapping ?: 'fq2bam'}/${sample_id}" }, mode: 'copy', pattern: "*.bam*"
    
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
        --read-group-sm ${sample_id} \\
        --num-gpus ${task.accelerator?.request ?: 1} \\
        --tmp-dir ./pbrun_tmp
    """
}
