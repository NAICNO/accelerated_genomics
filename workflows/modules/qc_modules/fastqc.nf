#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process fastqc {
    publishDir "Results/${PROCESSOR}/${S_NAME}/QC/fastqc", mode: 'symlink', overwrite: true

    input:
    path(R1)
    path(R2)
    val(S_NAME)
    val(PROCESSOR)

    output:
    file "*.{zip,html}"
    
    script:
    """
    fastqc -t ${task.cpus} -o . ${R1} ${R2}
    """

}
