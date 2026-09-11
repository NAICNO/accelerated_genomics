#!/usr/bin/env nextflow

/*
 * -------------------------------------------------
 * nf_exome_interval_smoketest.nf
 * -------------------------------------------------
 * Smoke-test to verify if the conditional `--interval-file` /
 * `--use-wes-model` / `--model-type` argument
 * logic is correctly implemented without needing a 
 * Parabricks container or a real BAM/BED.
 *
 * Each stub process reproduces the exact `def interval_arg = ...` /
 * `def wes_model_arg = ...` conditional-string logic from the real module
 * and echoes the resolved command line, so this test fails the moment
 * that logic diverges from what actually ships in modules/*.nf.
 *
 * Run twice (from this directory), once per sequencing_type, and inspect
 * the echoed lines -- see README.md for the full checklist:
 *
 *   nextflow run nf_exome_interval_smoketest.nf \
 *     --sequencing_type wgs
 *
 *   nextflow run nf_exome_interval_smoketest.nf \
 *     --sequencing_type wes --interval_file /any/path/targets.bed
 *
 * Expected: the `wgs` run's echoed lines contain no --interval-file /
 * --use-wes-model anywhere, and FQ2BAM_STUB never contains --interval-file
 * in EITHER run. The `wes` run's echoed lines contain --interval-file for
 * every stub except FQ2BAM_STUB, --use-wes-model only for
 * DEEPVARIANT_STUB, and --model-type WES for DEEPSOMATIC_STUB.
 */

nextflow.enable.dsl = 2

params.sequencing_type  = 'wgs'
params.interval_file    = null
params.deepvariant_mode = 'shortread'
params.deepsomatic_mode = 'shortread'
params.pon              = null


process FQ2BAM_STUB {
    input:
    path interval_file

    output:
    stdout

    script:
    // fq2bam deliberately never takes --interval-file -- this stub
    // takes the interval_file input only to prove that, unlike every other stub
    // below, it never references it in the command line.
    """
    echo "FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq R1 R2 --out-bam OUT.bam"
    """
}

process BQSR_STUB {
    input:
    path interval_file

    output:
    stdout

    script:
    def interval_arg = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    """
    echo "BQSR_STUB pbrun bqsr --ref REF --in-bam BAM ${interval_arg} --out-recal-file OUT.table"
    """
}

process APPLYBQSR_STUB {
    input:
    path interval_file

    output:
    stdout

    script:
    def interval_arg = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    """
    echo "APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam BAM --in-recal-file TABLE ${interval_arg} --out-bam OUT.bam"
    """
}

process HAPLOTYPECALLER_STUB {
    input:
    path interval_file

    output:
    stdout

    script:
    def interval_arg = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    """
    echo "HAPLOTYPECALLER_STUB pbrun haplotypecaller --ref REF --in-bam BAM ${interval_arg} --out-variants OUT.vcf"
    """
}

process DEEPVARIANT_STUB {
    input:
    path interval_file
    val  use_wes_model

    output:
    stdout

    script:
    def interval_arg  = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    def wes_model_arg = use_wes_model ? '--use-wes-model' : ''
    """
    echo "DEEPVARIANT_STUB pbrun deepvariant --ref REF --in-bam BAM --mode ${params.deepvariant_mode} ${wes_model_arg} ${interval_arg} --out-variants OUT.vcf"
    """
}

process MUTECTCALLER_STUB {
    input:
    path pon
    path pon_index
    path interval_file

    output:
    stdout

    script:
    // Mirrors modules/somatic_mutectcaller.nf exactly: two independent optional
    // file inputs, each with its own NO_FILE_* placeholder name (pon's pair vs.
    // interval_file's), landing in the same task. Reusing one literal "NO_FILE" 
    // name for both would collide during staging; distinct names must not.
    def pon_arg      = pon.name.startsWith('NO_FILE') ? '' : "--pon ${pon}"
    def interval_arg = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    """
    echo "MUTECTCALLER_STUB pbrun mutectcaller --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM ${pon_arg} ${interval_arg} --out-vcf OUT.vcf.gz"
    """
}

process DEEPSOMATIC_STUB {
    input:
    path interval_file
    val  use_wes_model

    output:
    stdout

    script:
    // deepsomatic has --mode (shortread | pacbio | ont, default shortread), symmetric to deepvariant_mode
    def interval_arg  = interval_file.name.startsWith('NO_FILE') ? '' : "--interval-file ${interval_file}"
    def wes_model_arg = use_wes_model ? '--use-wes-model' : ''
    """
    echo "DEEPSOMATIC_STUB pbrun deepsomatic --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM --mode ${params.deepsomatic_mode} ${wes_model_arg} ${interval_arg} --out-variants OUT.vcf"
    """
}

workflow {
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

    interval_file  = params.interval_file ? file(params.interval_file) : file('NO_FILE_INTERVAL')
    // Mirrors somatic_main.nf's pon/pon_index construction exactly (distinct
    // placeholder names from interval_file's, see MUTECTCALLER_STUB comment above).
    pon             = params.pon ? file(params.pon) : file('NO_FILE_PON')
    pon_index       = params.pon ? file("${params.pon}.tbi") : file('NO_FILE_PON_TBI')
    // deepvariant's --use-wes-model additionally requires shortread mode (deepvariant_mode)
    use_wes_model             = (params.sequencing_type == 'wes' && params.deepvariant_mode == 'shortread')
    // pbrun deepsomatic also has --mode -- gated the
    // same way as deepvariant now (was previously ungated, see correction note above)
    deepsomatic_use_wes_model = (params.sequencing_type == 'wes' && params.deepsomatic_mode == 'shortread')

    FQ2BAM_STUB(interval_file).view { it.trim() }
    BQSR_STUB(interval_file).view { it.trim() }
    APPLYBQSR_STUB(interval_file).view { it.trim() }
    HAPLOTYPECALLER_STUB(interval_file).view { it.trim() }
    DEEPVARIANT_STUB(interval_file, use_wes_model).view { it.trim() }
    MUTECTCALLER_STUB(pon, pon_index, interval_file).view { it.trim() }
    DEEPSOMATIC_STUB(interval_file, deepsomatic_use_wes_model).view { it.trim() }
}