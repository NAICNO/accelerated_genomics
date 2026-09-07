#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_resource_sweep_verification.nf
 * -------------------------------------------------
 * Verification test: exercises EVERY process in modules/*.nf 
 * against the pipeline's resource-sizing configs and cluster configs,
 * and writes resolved cpus/time/ext.mem_gb/label to one TSV file.
 *
 * Each process's row is built with a plain inline echo, interpolating
 * task.cpus/task.time/task.ext.mem_gb directly in that process's own
 * script string.
 *
 * Stub process list below is hand-maintained and can drift from the real
 * pipeline if a process is added/renamed/relabeled in modules/*.nf without
 * updating this file. Run check_stub_sync.sh in this directory before
 * trusting a sweep run -- it greps modules/*.nf for the current process
 * list and fails loudly on any mismatch.
 *
 * Run (from this directory), once per cluster/profile combo:
 *   nextflow run nf_resource_sweep_verification.nf -c nf_resource_sweep_verification.config -profile tsd,production
 *   nextflow run nf_resource_sweep_verification.nf -c nf_resource_sweep_verification.config -profile tsd,test
 *   nextflow run nf_resource_sweep_verification.nf -c nf_resource_sweep_verification.config -profile fox,production
 *   nextflow run nf_resource_sweep_verification.nf -c nf_resource_sweep_verification.config -profile fox,test
 *
 * Output: resource_sweep_results.tsv in the working directory (each run
 * overwrites it -- rename/move it before running the next combo, see
 * README.md).
 */

nextflow.enable.dsl = 2

// ---- label 'gpu_process'

process FQ2BAM {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tFQ2BAM\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process BQSR {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tBQSR\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process APPLYBQSR {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tAPPLYBQSR\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process MUTECTCALLER {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tMUTECTCALLER\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process DEEPSOMATIC {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tDEEPSOMATIC\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process DEEPVARIANT {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tDEEPVARIANT\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

process HAPLOTYPECALLER {
    label 'gpu_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tHAPLOTYPECALLER\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tgpu_process"
    """
}

// ---- label 'leaf_process'

process PREPON {
    label 'leaf_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tPREPON\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tleaf_process"
    """
}

process POSTPON {
    label 'leaf_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tPOSTPON\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tleaf_process"
    """
}

process VCFQC {
    label 'leaf_process'
    output: stdout
    script:
    """
    echo "${workflow.profile}\tVCFQC\t${task.cpus}\t${task.time}\t${task.ext.mem_gb}\tleaf_process"
    """
}

workflow {

    // Mirrors the same fail-fast check nf_config_merge_smoketest.nf uses
    // and the real workflow entrypoints (germline_workflow.nf /
    // somatic_main.nf)
    if (!params._resource_profile) {
        error "No resource-sizing profile selected. Add `production` or `test` " +
              "to -profile alongside `tsd`/`fox`, e.g. -profile tsd,test"
    }

    results = FQ2BAM().mix(
        BQSR(), APPLYBQSR(), MUTECTCALLER(), DEEPSOMATIC(), DEEPVARIANT(),
        HAPLOTYPECALLER(), PREPON(), POSTPON(), VCFQC()
    )

    results
        .map { it.trim() }
        .collectFile(
            name: 'resource_sweep_results.tsv',
            storeDir: '.',
            newLine: true,
            sort: true,
            seed: "cluster_profile\tprocess\tcpus\ttime\tmem_gb\tlabel"
        )
        .view { "Wrote resource sweep results to: $it" }
}
