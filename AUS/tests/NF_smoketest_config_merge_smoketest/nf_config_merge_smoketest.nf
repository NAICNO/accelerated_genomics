#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_config_merge_smoketest.nf
 * -------------------------------------------------
 * Verifies if that the cluster identity and the production/test configs 
 * actually MERGE the way the split assumes, once real
 * `includeConfig`'d files are combined via -profile.
 *
 * None of the existing smoke tests can answer this:
 *   - gpu_diag_smoketest / gpu_fq2bam_smoketest are standalone `sbatch`
 *     scripts calling `pbrun` directly -- no Nextflow config parser
 *     involved at all.
 *   - hello_world.nf is Nextflow, but defines its `tsd`/`local` profiles
 *     inline in one file, single process, no withLabel/withName
 *     selectors split across multiple included configs.
 *
 * Two dummy (`echo`-only) processes, named after real processes so it's
 * obvious which selectors each one exercises:
 *
 *   FQ2BAM  -- label 'gpu_process'. Exercises withLabel:gpu_process from
 *              the cluster file (queue, clusterOptions/GPU flags,
 *              accelerator) MERGED with withName:FQ2BAM from the
 *              resource file (cpus/time/memory). On TSD this also
 *              exercises the clusterOptions closure that derives
 *              --mem-per-cpu from task.memory/task.cpus.
 *   PREPON  -- no label. Exercises the cluster file's plain process{}
 *              defaults (executor, clusterOptions, containerOptions)
 *              MERGED with withName:PREPON from the resource file
 *              (cpus/time/memory). No GPU allocation needed, small
 *              footprint.
 *
 * Since directives like `clusterOptions` aren't inspectable from inside
 * a process script, verification is NOT done by what these processes
 * print -- it's done by reading the real `.command.run` Nextflow writes
 * for each task's work directory after the run, e.g.:
 *
 *   grep -E '^#SBATCH|--mem-per-cpu|--gpus|--gres' work/<hash>/.command.run
 *
 * See nf-config-merge-smoke-test.md in this directory for the full
 * checklist of what to confirm there.
 *
 * Run (from this directory):
 *   nextflow run nf_config_merge_smoketest.nf \
 *     -c nf_config_merge_smoketest.config -profile tsd,test
 *
 * Deliberately-failing check (validates open decision 3 -- production/test
 * are mandatory): omit both resource profiles and confirm the workflow
 * errors out immediately, before submitting anything:
 *   nextflow run nf_config_merge_smoketest.nf \
 *     -c nf_config_merge_smoketest.config -profile tsd
 */

nextflow.enable.dsl = 2

process FQ2BAM {
    label 'gpu_process'

    output:
    stdout

    script:
    """
    echo "FQ2BAM stub on \$(hostname), job \${SLURM_JOB_ID:-<unset>}"
    echo "partition=\${SLURM_JOB_PARTITION:-<unset>} account=\${SLURM_JOB_ACCOUNT:-<unset>}"
    echo "CUDA_VISIBLE_DEVICES=\${CUDA_VISIBLE_DEVICES:-<unset>}"
    """
}

process PREPON {
    output:
    stdout

    script:
    """
    echo "PREPON stub on \$(hostname), job \${SLURM_JOB_ID:-<unset>}"
    echo "partition=\${SLURM_JOB_PARTITION:-<unset>} account=\${SLURM_JOB_ACCOUNT:-<unset>}"
    """
}

workflow {

    // ---- resource-sizing profile check ----
    // Mirrors the exact check added to germline_workflow.nf / somatic_main.nf
    // AUS/configs/[resources_production|resources_test].conf set _resource_profile 
    // params._resource_profile marker asserting exercises the fail-fast mechanism
    if (!params._resource_profile) {
        error "No resource-sizing profile selected. Add `production` or `test` " +
              "to -profile alongside `tsd`/`fox`, e.g. -profile tsd,test"
    }

    FQ2BAM_OUT = FQ2BAM()
    PREPON_OUT = PREPON()

    FQ2BAM_OUT.view { "FQ2BAM  -> ${it.trim()}" }
    PREPON_OUT.view { "PREPON  -> ${it.trim()}" }
}
