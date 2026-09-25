/*
 * giraffe: GPU-accelerated pangenome-graph alignment, sorting, and
 * duplicate marking (`pbrun giraffe`). The germline pipeline's second,
 * selectable aligner -- chosen with --germline_mapping giraffe, fq2bam stays
 * the default.
 * Germline-only: never included by somatic_main.nf until explicitly decided.
 *
 *
 * Deliberately no --ref (the tool has none -- downstream BQSR/callers take
 * a FASTA extracted from the SAME graph) and no --interval-file (as in fq2bam)
 *
 * Kept in lockstep with tests/nf_giraffe_arg_smoketest/ (GIRAFFE_STUB) --
 * run `bash check_module_sync.sh` there after any edit.
 */

process GIRAFFE {
    tag "${sample_id}"
    label 'gpu_process'
    container params.parabricks_container

    // safe here: this module is germline-only, where the param always has a
    // value (default 'fq2bam' in germline.config).
    publishDir { "${params.outdir}/bam/${params.germline_mapping}/${sample_id}" }, mode: 'copy', pattern: "*.bam*"
    publishDir { "${params.outdir}/qc/bam/${params.germline_mapping}/${sample_id}" }, mode: 'copy', pattern: "*.duplicate_metrics.txt"

    input:
    tuple val(sample_id), val(sample_type), path(fastq_1), path(fastq_2)
    path graph_gbz
    path graph_dist
    path graph_min
    path graph_zipcodes
    path graph_ref_paths

    output:
    tuple val(sample_id), val(sample_type), path("${sample_id}.bam"), path("${sample_id}.bam.bai"), emit: bam
    path "${sample_id}.duplicate_metrics.txt", emit: dup_metrics

    script:
    """
    pbrun giraffe \\
        --in-fq ${fastq_1} ${fastq_2} \\
        --gbz-name ${graph_gbz} \\
        --dist-name ${graph_dist} \\
        --minimizer-name ${graph_min} \\
        --zipcodes-name ${graph_zipcodes} \\
        --ref-paths ${graph_ref_paths} \\
        --out-bam ${sample_id}.bam \\
        --out-duplicate-metrics ${sample_id}.duplicate_metrics.txt \\
        --sample ${sample_id} \\
        --read-group ${sample_id} \\
        --num-gpus ${task.accelerator?.request ?: 1} \\
        --tmp-dir ./pbrun_tmp
    """
}
