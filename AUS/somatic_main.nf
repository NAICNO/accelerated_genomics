#!/usr/bin/env nextflow

/*
 * GPU-accelerated somatic variant calling with NVIDIA Clara Parabricks.
 *
 * [Tumor FASTQ]  --> fq2bam --> [Tumor BAM]  --+
 *                                               +--> bqsr --> applybqsr --+--> mutectcaller --> postpon --> [Mutect2 VCF]
 * [Normal FASTQ] --> fq2bam --> [Normal BAM] --+                         |                  --> vcfqc
 *                                                                        +--> deepsomatic ------------------> [DeepSomatic VCF]
 *
 * fq2bam/bqsr/applybqsr each run once per tumor+normal pair via a single
 * tagged channel, so one process definition handles both samples. These
 * three modules are shared preprocessing steps -- the planned germline
 * workflow will reuse them unchanged, which is why they aren't prefixed
 * with "somatic_" like the caller-specific modules below.
 *
 * prepon (contamination/pileup prep) runs alongside mutectcaller and
 * feeds postpon/FilterMutectCalls -- see modules/somatic_prepon.nf and
 * modules/somatic_postpon.nf for why it's wired there rather than into
 * mutectcaller directly.
 *
 * See somatic.config for params and `-profile tsd` usage.
 */

nextflow.enable.dsl = 2

include { FQ2BAM       } from './modules/fq2bam.nf'
include { BQSR         } from './modules/bqsr.nf'
include { APPLYBQSR    } from './modules/applybqsr.nf'
include { PREPON       } from './modules/somatic_prepon.nf'
include { MUTECTCALLER } from './modules/somatic_mutectcaller.nf'
include { POSTPON      } from './modules/somatic_postpon.nf'
include { DEEPSOMATIC  } from './modules/somatic_deepsomatic.nf'
include { VCFQC        } from './modules/somatic_vcfqc.nf'

workflow {

    // ---- required params check ----
    def required = [
        'tumor_id', 'tumor_fastq_1', 'tumor_fastq_2',
        'normal_id', 'normal_fastq_1', 'normal_fastq_2',
        'ref', 'known_sites', 'germline_resource',
        'parabricks_container', 'gatk_container', 'bcftools_container'
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

    // ---- germline resource for contamination estimation ----
    germline_resource       = file(params.germline_resource)
    germline_resource_index = file("${params.germline_resource}.tbi")

    // ---- optional Mutect2 panel of normals ----
    pon       = params.pon ? file(params.pon) : file('NO_FILE_PON')
    pon_index = params.pon ? file("${params.pon}.tbi") : file('NO_FILE_PON_TBI')

    // ---- tumor + normal FASTQ, tagged so a single FQ2BAM process handles both ----
    ch_reads = Channel.of(
        tuple(params.tumor_id,  'tumor',  file(params.tumor_fastq_1),  file(params.tumor_fastq_2)),
        tuple(params.normal_id, 'normal', file(params.normal_fastq_1), file(params.normal_fastq_2))
    )

    FQ2BAM(ch_reads, ref, ref_index, ref_dict)
    BQSR(FQ2BAM.out.bam, ref, ref_index, ref_dict, known_sites_vcfs, known_sites_tbis)
    APPLYBQSR(BQSR.out.recal, ref, ref_index, ref_dict)

    // split the recalibrated BAMs back into tumor/normal channels
    APPLYBQSR.out.bam
        .branch {
            tumor:  it[1] == 'tumor'
            normal: it[1] == 'normal'
        }
        .set { ch_recal }

    ch_tumor_bam  = ch_recal.tumor.map  { sample_id, sample_type, bam, bai -> tuple(sample_id, bam, bai) }
    ch_normal_bam = ch_recal.normal.map { sample_id, sample_type, bam, bai -> tuple(sample_id, bam, bai) }

    // ---- Mutect2 branch: mutectcaller -> {postpon -> filtered VCF, vcfqc} ----
    MUTECTCALLER(ch_tumor_bam, ch_normal_bam, ref, ref_index, ref_dict, pon, pon_index)
    PREPON(ch_tumor_bam, ch_normal_bam, ref, ref_index, ref_dict, germline_resource, germline_resource_index)
    POSTPON(MUTECTCALLER.out.vcf, PREPON.out.contamination, ref, ref_index, ref_dict)
    VCFQC(MUTECTCALLER.out.vcf)

    // ---- DeepSomatic branch (standalone) ----
    DEEPSOMATIC(ch_tumor_bam, ch_normal_bam, ref, ref_index, ref_dict)
}
