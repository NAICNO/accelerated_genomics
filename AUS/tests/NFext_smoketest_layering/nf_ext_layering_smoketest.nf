#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_ext_layering_smoketest.nf
 * -------------------------------------------------
* When a process matches an ext-setting withLabel block AND a more
 * specific ext-setting withName block, does Nextflow's merge take the
 * more-specific block's map WHOLESALE (overwrite), or shallow-merge keys
 * from both levels?
 *
 * LAYERED   -- matches BOTH withLabel:has_default and withName:LAYERED.
 * LABEL_ONLY -- matches ONLY withLabel:has_default; control process,
 *               confirms the label-level default is visible at all.
 *
 * Local executor, no profile needed -- this isn't about TSD vs Fox, it's
 * about Nextflow's directive-merge semantics for the version(s) in use.
 *
 * Run (from this directory):
 *   nextflow run nf_ext_layering_smoketest.nf -c nf_ext_layering_smoketest.config
 *
 * See README.md in this directory for the full checklist.
 */

nextflow.enable.dsl = 2

process LAYERED {
    label 'has_default'

    output:
    stdout

    script:
    """
    echo "LAYERED RESOLVED task.ext=${task.ext}"
    """
}

process LABEL_ONLY {
    label 'has_default'

    output:
    stdout

    script:
    """
    echo "LABEL_ONLY RESOLVED task.ext=${task.ext}"
    """
}

workflow {
    LAYERED().view    { "LAYERED    -> ${it.trim()}" }
    LABEL_ONLY().view { "LABEL_ONLY -> ${it.trim()}" }
}
