#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_giraffe_arg_smoketest.nf
 * -------------------------------------------------
 * Smoketest for local, no-container, no-GPU check for the planned `--germline_mapping` logic.
 * Written BEFORE modules/giraffe.nf exists.
 * The stubs below ARE the target the real code must match.
 *
 * Test for
 *   - germline_workflow.nf's fail-fast block: germline_mapping enum,
 *     graph_* required under 'giraffe', rejected under 'fq2bam'.
 *   - the aligner branch: exactly one of GIRAFFE / FQ2BAM runs, and its
 *     output feeds one shared ch_aligned_bam into BQSR.
 *   - GIRAFFE's pbrun command line: the five graph flags, paired --in-fq,
 *     --sample/--read-group (NOT --read-group-sm), and no --ref or
 *     --interval-file, even for a WES run.
 *   - publishDir nesting: bam/<mapping>/<sample>, with the
 *     `params.germline_mapping ?: 'fq2bam'` fallback in the shared
 *     modules (FQ2BAM, APPLYBQSR) when germline_mapping is unset, as it
 *     is under somatic_main.nf. Stubs touch empty files and really
 *     publish them, so the closure form is parsed and exercised, not just
 *     echoed.
 *
 * Two entrypoints, selected with --entrypoint:
 *   germline (default) -- run WITH -c nf_giraffe_arg_smoketest.config,
 *                         which carries the param defaults planned for
 *                         germline.config (germline_mapping = 'fq2bam').
 *   somatic            -- run WITHOUT -c, so germline_mapping stays null,
 *                         like somatic.config. Only the shared stubs run.
 *
 */

nextflow.enable.dsl = 2

params.entrypoint       = 'germline'
params.germline_mapping = null   // germline default ('fq2bam') comes from the -c config
params.sequencing_type  = 'wgs'
params.interval_file    = null
params.sample_id        = 'SAMPLE01'
params.fastq_1          = 'S_R1.fastq.gz'
params.fastq_2          = 'S_R2.fastq.gz'
params.graph_gbz        = null
params.graph_dist       = null
params.graph_min        = null
params.graph_zipcodes   = null
params.graph_ref_paths  = null
params.outdir           = 'results'


// ---- planned modules/giraffe.nf (germline-only: plain interpolation, no elvis) ----
process GIRAFFE_STUB {
    tag "${sample_id}"
    publishDir { "${params.outdir}/bam/${params.germline_mapping}/${sample_id}" }, mode: 'copy', pattern: "*.bam*"

    input:
    tuple val(sample_id), val(sample_type), path(fastq_1), path(fastq_2)
    path graph_gbz
    path graph_dist
    path graph_min
    path graph_zipcodes
    path graph_ref_paths
    path interval_file   // passed in only to prove it is never used (spec 5c)

    output:
    tuple val(sample_id), val(sample_type), path("${sample_id}.bam"), path("${sample_id}.bam.bai"), emit: bam
    stdout emit: cmd

    script:
    """
    touch ${sample_id}.bam ${sample_id}.bam.bai
    echo "GIRAFFE_STUB pbrun giraffe --in-fq ${fastq_1} ${fastq_2} --gbz-name ${graph_gbz} --dist-name ${graph_dist} --minimizer-name ${graph_min} --zipcodes-name ${graph_zipcodes} --ref-paths ${graph_ref_paths} --out-bam ${sample_id}.bam --out-duplicate-metrics ${sample_id}.duplicate_metrics.txt --sample ${sample_id} --read-group ${sample_id} --num-gpus ${task.accelerator?.request ?: 1} --tmp-dir ./pbrun_tmp"
    """
}

// ---- modules/fq2bam.nf (shared with somatic: elvis fallback, spec 5h) ----
process FQ2BAM_STUB {
    tag "${sample_id}"
    publishDir { "${params.outdir}/bam/${params.germline_mapping ?: 'fq2bam'}/${sample_id}" }, mode: 'copy', pattern: "*.bam*"

    input:
    tuple val(sample_id), val(sample_type), path(fastq_1), path(fastq_2)

    output:
    tuple val(sample_id), val(sample_type), path("${sample_id}.bam"), path("${sample_id}.bam.bai"), emit: bam
    stdout emit: cmd

    script:
    """
    touch ${sample_id}.bam ${sample_id}.bam.bai
    echo "FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq ${fastq_1} ${fastq_2} --out-bam ${sample_id}.bam"
    """
}

// ---- modules/bqsr.nf (no publishDir today -- spec 5h's listing of it is stale) ----
process BQSR_STUB {
    tag "${sample_id}"

    input:
    tuple val(sample_id), val(sample_type), path(bam), path(bai)

    output:
    stdout

    script:
    """
    echo "BQSR_STUB pbrun bqsr --ref REF --in-bam ${bam} (aligner=${params.germline_mapping ?: 'fq2bam'})"
    """
}

// ---- modules/applybqsr.nf (shared with somatic: elvis fallback, spec 5h) ----
process APPLYBQSR_STUB {
    tag "${sample_id}"
    publishDir { "${params.outdir}/bam_recal/${params.germline_mapping ?: 'fq2bam'}/${sample_id}" }, mode: 'copy', pattern: "*.bam*"

    input:
    tuple val(sample_id), val(sample_type), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.recal.bam"), path("${sample_id}.recal.bam.bai"), emit: bam
    stdout emit: cmd

    script:
    """
    touch ${sample_id}.recal.bam ${sample_id}.recal.bam.bai
    echo "APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam ${bam} --out-bam ${sample_id}.recal.bam"
    """
}


workflow {
    if (params.entrypoint !in ['germline', 'somatic']) {
        error "params.entrypoint must be 'germline' or 'somatic', got: ${params.entrypoint}"
    }

    ch_reads = Channel.of(
        tuple(params.sample_id, params.entrypoint, file(params.fastq_1), file(params.fastq_2))
    )

    if (params.entrypoint == 'somatic') {
        // somatic_main.nf never validates or sets germline_mapping -- the shared
        // modules must still publish to a real directory, not bam/null/.
        FQ2BAM_STUB(ch_reads)
        FQ2BAM_STUB.out.cmd.view { it.trim() }
        APPLYBQSR_STUB(FQ2BAM_STUB.out.bam)
        APPLYBQSR_STUB.out.cmd.view { it.trim() }
    } else {

        // ---- germline_workflow.nf: required params ----
        def required = ['sample_id', 'fastq_1', 'fastq_2', 'germline_mapping']
        def missing = required.findAll { params[it] == null }
        if (missing) error "Missing required params: ${missing.join(', ')}"

        // ---- germline_workflow.nf: exome checks (unchanged, needed for the WES case) ----
        if (params.sequencing_type !in ['wgs', 'wes']) {
            error "params.sequencing_type must be 'wgs' or 'wes', got: ${params.sequencing_type}"
        }
        if (params.sequencing_type == 'wes' && !params.interval_file) {
            error "sequencing_type = 'wes' requires --interval_file"
        }
        if (params.sequencing_type == 'wgs' && params.interval_file) {
            error "--interval_file was given but sequencing_type is 'wgs' (default) -- " +
                  "set --sequencing_type wes to actually apply it, or drop --interval_file."
        }
        interval_file = params.interval_file ? file(params.interval_file) : file('NO_FILE_INTERVAL')

        // ---- germline_workflow.nf: aligner selection ----
        if (params.germline_mapping !in ['giraffe', 'fq2bam']) {
            error "params.germline_mapping must be 'giraffe' or 'fq2bam', got: ${params.germline_mapping}"
        }
        def graph_params = ['graph_gbz', 'graph_dist', 'graph_min', 'graph_zipcodes', 'graph_ref_paths']
        if (params.germline_mapping == 'giraffe') {
            def missing_graph = graph_params.findAll { params[it] == null }
            if (missing_graph) error "germline_mapping = 'giraffe' requires: ${missing_graph.join(', ')} " +
                                     "-- see params.germline.yaml.example for the giraffe branch."
        } else {
            def set_graph = graph_params.findAll { params[it] != null }
            if (set_graph) error "${set_graph.join(', ')} ${set_graph.size() > 1 ? 'were' : 'was'} given but " +
                                 "germline_mapping is 'fq2bam' -- set --germline_mapping giraffe to actually " +
                                 "use ${set_graph.size() > 1 ? 'them' : 'it'}, or drop ${set_graph.size() > 1 ? 'them' : 'it'}."
        }

        // ---- germline_workflow.nf: branch, then one shared channel into BQSR ----
        if (params.germline_mapping == 'giraffe') {
            GIRAFFE_STUB(ch_reads,
                file(params.graph_gbz), file(params.graph_dist), file(params.graph_min),
                file(params.graph_zipcodes), file(params.graph_ref_paths), interval_file)
            GIRAFFE_STUB.out.cmd.view { it.trim() }
            ch_aligned_bam = GIRAFFE_STUB.out.bam
        } else {
            FQ2BAM_STUB(ch_reads)
            FQ2BAM_STUB.out.cmd.view { it.trim() }
            ch_aligned_bam = FQ2BAM_STUB.out.bam
        }

        BQSR_STUB(ch_aligned_bam).view { it.trim() }
        APPLYBQSR_STUB(ch_aligned_bam)
        APPLYBQSR_STUB.out.cmd.view { it.trim() }
    }
}
