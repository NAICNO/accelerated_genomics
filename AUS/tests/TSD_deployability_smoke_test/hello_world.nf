/*
 * -------------------------------------------------
 * hello_world.nf
 * -------------------------------------------------
 * Minimal Nextflow DSL2 smoke test.
 *
 * Purpose: confirm that a plain Nextflow run can complete end-to-end on
 * TSD/Colossus (Nextflow itself launches, the SLURM executor submits a
 * job, the job runs and reports output back) BEFORE debugging anything
 * about the real GPU/Parabricks pipelines (somatic_main.nf /
 * germline_workflow.nf). No containers, no GPUs, no reference data --
 * just `echo`. If this doesn't complete, the problem is in the
 * Nextflow/SLURM/account plumbing, not in the pipelines.
 *
 * Run (from this directory, on the TSD submit node):
 *   nextflow run hello_world.nf -c hello_world.config -profile tsd
 *
 * See docs/tsd-smoke-test.md (in the repo root) for the full walkthrough,
 * expected output, and troubleshooting.
 */

nextflow.enable.dsl=2

process SAY_HELLO {
    output:
    stdout

    script:
    """
    echo "Hello, HPC World! Nextflow is working successfully."
    """
}

workflow {
    // Run the process and print the standard output to the console
    SAY_HELLO | view
}
