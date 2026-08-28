/*
 * -------------------------------------------------
 * cpu_container_smoketest.nf
 * -------------------------------------------------
 * Second TSD deployability smoke test: after hello_world.nf confirmed
 * plain Nextflow + SLURM + your account work (see
 * TSD_deployability_smoke_test), this one confirms CPU-based processes AND
 * Apptainer/Singularity containers work -- running the same two CPU
 * tools (`gatk CollectWgsMetrics`, `bcftools stats`) the real pipelines
 * already use for QC (modules/somatic_postpon.nf, modules/somatic_prepon.nf
 * and modules/*_vcfqc.nf), against whatever real bam_recal/ and vcf/
 * output you already have from a prior germline/somatic run on this
 * cluster. Still no GPU involved.
 *
 *   1. `params.fasta` renamed to `params.ref`, with `ref_index` (.fai)
 *      and `ref_dict` (.dict) added as explicit path inputs, staged
 *      alongside the FASTA the same way germline_workflow.nf /
 *      somatic_main.nf already derive them (see the "reference bundle"
 *      comment in both). The original script staged only the FASTA
 *      itself -- `gatk CollectWgsMetrics -R` requires the .fai and
 *      .dict sitting next to it, and Nextflow does not auto-stage
 *      companion files just because they share a basename; without
 *      declaring them as inputs they would not exist in the process's
 *      sandboxed work directory and the tool would fail with a missing
 *      index/dictionary error, not a container problem.
 *   2. `label 'leaf_process'` added to both processes, matching the
 *      label the real *_vcfqc.nf QC modules use: a QC-only smoke test
 *      failing on a flaky node shouldn't be treated as fatal the way a
 *      core pipeline step would be (see TSD.config's leaf_process
 *      definition -- retry once, then ignore).
 *
 * No `.fasta`/`.sif` example paths are hardcoded here on purpose -- set
 * params.ref / params.bams / params.vcfs / params.*_container via
 * cpu_container_smoketest.config or a -params-file (see
 * params.cpu_smoketest.yaml.example and
 * docs/tsd-cpu-container-smoke-test.md for the full walkthrough).
 */

nextflow.enable.dsl=2

process COLLECT_WGS_METRICS {
    tag "${sample_id}"
    label 'leaf_process'
    container params.gatk_container
    publishDir "${params.outdir}/metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref
    path ref_index
    path ref_dict

    output:
    path "${sample_id}.wgs_metrics.txt"

    script:
    """
    # GATK4 uses the 'gatk' wrapper for Picard tools
    gatk CollectWgsMetrics \\
        -I ${bam} \\
        -O ${sample_id}.wgs_metrics.txt \\
        -R ${ref}
    """
}

process BCFTOOLS_STATS {
    tag "${vcf.baseName}"
    label 'leaf_process'
    container params.bcftools_container
    publishDir "${params.outdir}/stats", mode: 'copy'

    input:
    path vcf

    output:
    path "${vcf.baseName}.stats"

    script:
    """
    bcftools stats ${vcf} > ${vcf.baseName}.stats
    """
}

workflow {
    // ---- reference bundle: FASTA + .fai + .dict expected alongside
    //      params.ref, same convention as germline_workflow.nf /
    //      somatic_main.nf ----
    ref       = file(params.ref)
    ref_index = file("${params.ref}.fai")
    ref_dict  = file(params.ref.replaceAll(/\.(fa|fasta)(\.gz)?$/, '') + '.dict')

    // Stage BAMs and dynamically link their .bai indices -- matches the
    // ${sample_id}.recal.bam / ${sample_id}.recal.bam.bai naming
    // APPLYBQSR actually publishes (modules/applybqsr.nf), so the
    // default params.bams glob below can point straight at a prior
    // run's bam_recal/ output.
    bam_ch = Channel
        .fromPath(params.bams)
        .map { bam -> tuple(bam.baseName, bam, file("${bam}.bai")) }

    vcf_ch = Channel.fromPath(params.vcfs)

    // Execute processes
    COLLECT_WGS_METRICS(bam_ch, ref, ref_index, ref_dict)
    BCFTOOLS_STATS(vcf_ch)
}
