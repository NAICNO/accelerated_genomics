#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_ext_multikey_smoketest.nf
 * -------------------------------------------------
 * Does a map-literal ext assignment with MULTIPLE keys in one selector
 * block (ext = [ mem_gb: N, threads: M ]) resolve all keys correctly
 * per-process, or does a second key reintroduce cross-selector leakage
 * that the single-key case (already tested) happened not to expose?
 *
 * X/Y/Z each get a two-key ext map with values chosen so no key's value
 * collides with another process's same key OR the other key in its own
 * map -- any cross-leak, of either key, in either direction, is
 * immediately visible in the printed output.
 *
 * Run (from this directory):
 *   nextflow run nf_ext_multikey_smoketest.nf -c nf_ext_multikey_smoketest.config
 *
 * See nf-ext-multikey-smoke-test.md in this directory for the full checklist.
 */

nextflow.enable.dsl = 2

process X {
    output:
    stdout

    script:
    """
    echo "X RESOLVED mem_gb=${task.ext.mem_gb} threads=${task.ext.threads}"
    """
}

process Y {
    output:
    stdout

    script:
    """
    echo "Y RESOLVED mem_gb=${task.ext.mem_gb} threads=${task.ext.threads}"
    """
}

process Z {
    output:
    stdout

    script:
    """
    echo "Z RESOLVED mem_gb=${task.ext.mem_gb} threads=${task.ext.threads}"
    """
}

workflow {
    X().view { "X -> ${it.trim()}" }
    Y().view { "Y -> ${it.trim()}" }
    Z().view { "Z -> ${it.trim()}" }
}
