#!/usr/bin/env nextflow

/*
 * GPU-accelerated germline variant calling with NVIDIA Clara Parabricks.
 *
 * [Sample FASTQ] --> fq2bam --> [BAM] --> bqsr --> applybqsr --> [Recalibrated BAM] --+--> deepvariant     --> vcfqc
 *                                                                                      +--> haplotypecaller --> vcfqc
 *
 * fq2bam/bqsr/applybqsr are the exact modules used by the somatic workflow
 * (modules/fq2bam.nf, modules/bqsr.nf, modules/applybqsr.nf) -- unchanged
 * here, just fed a single-sample channel instead of a tumor/normal pair.
 * deepvariant/haplotypecaller/vcfqc are germline-specific modules,
 * prefixed "germline_" to mirror the "somatic_" modules used by
 * somatic_main.nf.
 *
 * NOTE: deepvariant and haplotypecaller emit different VCF flavors --
 * deepvariant writes bgzipped .vcf.gz + .tbi, haplotypecaller writes a
 * plain .vcf + .vcf.idx (pbrun haplotypecaller's htvc binary rejects a
 * .vcf.gz output name; see modules/germline_haplotypecaller.nf). VCFQC
 * takes generic path inputs so both flow through .mix() unchanged.
 *
 * No panel-of-normals prep/filtering (prepon/postpon) here -- that's a
 * Mutect2-specific concept from the somatic workflow and doesn't apply
 * to single-sample germline calling.
 *
 * See germline.config for params and `-profile tsd` usage.
 */

nextflow.enable.dsl = 2

include { FQ2BAM          } from './modules/fq2bam.nf'
include { BQSR            } from './modules/bqsr.nf'
include { APPLYBQSR       } from './modules/applybqsr.nf'
include { DEEPVARIANT     } from './modules/germline_deepvariant.nf'
include { HAPLOTYPECALLER } from './modules/germline_haplotypecaller.nf'
include { VCFQC           } from './modules/germline_vcfqc.nf'

workflow {

    // ---- required params check ----
    def required = [
        'sample_id', 'fastq_1', 'fastq_2',
        'ref', 'known_sites',
        'parabricks_container', 'bcftools_container'
    ]
    def missing = required.findAll { params[it] == null }
    if (missing) error "Missing required params: ${missing.join(', ')}"

    // ---- resource-sizing profile check ----
    // `production` and `test` (configs/resources_production.conf /
    // configs/resources_test.conf) are mandatory-selection profiles --
    // exactly one must be combined with `singularity` + (`tsd`/`fox`) on
    // the command line, e.g. -profile singularity,tsd,production.
    // Nextflow won't fail on its own just because a withName block is
    // missing, so this asserts the `_resource_profile` marker each of
    // those files sets
    if (!params._resource_profile) {
        error "No resource-sizing profile selected. Add `production` or `test` " +
              "to -profile alongside `singularity` and `tsd`/`fox`, e.g. " +
              "-profile singularity,tsd,test"
    }

    // ---- reference bundle: FASTA + .fai + .dict expected alongside params.ref ----
    ref       = file(params.ref)
    ref_index = file("${params.ref}.fai")
    ref_dict  = file(params.ref.replaceAll(/\.(fa|fasta)(\.gz)?$/, '') + '.dict')


    // ---- known-sites VCFs for BQSR, each needs a .tbi alongside. Accepts
    //      either a comma-separated string (--known_sites on the CLI) or a
    //      YAML list (-params-file params.yaml), since Nextflow maps a YAML
    //      list value straight to a Groovy List instead of a String. ----
    known_sites_paths = (params.known_sites instanceof List
        ? params.known_sites
        : params.known_sites.split(',') as List
    ).collect { it.toString().trim() }
    known_sites_vcfs  = known_sites_paths.collect { file(it) }
    known_sites_tbis  = known_sites_paths.collect { file("${it}.tbi") }

    // ---- single-sample FASTQ, tagged 'germline' to match the shared
    //      fq2bam/bqsr/applybqsr tuple shape (sample_id, sample_type, fq1, fq2) ----
    ch_reads = Channel.of(
        tuple(params.sample_id, 'germline', file(params.fastq_1), file(params.fastq_2))
    )

    FQ2BAM(ch_reads, ref, ref_index, ref_dict)
    BQSR(FQ2BAM.out.bam, ref, ref_index, ref_dict, known_sites_vcfs, known_sites_tbis)
    APPLYBQSR(BQSR.out.recal, ref, ref_index, ref_dict)

    ch_bam = APPLYBQSR.out.bam.map { sample_id, sample_type, bam, bai -> tuple(sample_id, bam, bai) }

    // ---- two callers in parallel off the same recalibrated BAM ----
    DEEPVARIANT(ch_bam, ref, ref_index, ref_dict)
    HAPLOTYPECALLER(ch_bam, ref, ref_index, ref_dict)

    // ---- one VCFQC process definition, run once per caller output ----
    VCFQC(DEEPVARIANT.out.vcf.mix(HAPLOTYPECALLER.out.vcf))
}
