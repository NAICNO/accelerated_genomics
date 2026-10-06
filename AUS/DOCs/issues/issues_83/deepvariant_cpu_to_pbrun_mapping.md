# CPU → Parabricks Parameter Mapping: deepvariant v4.7.1

Covers Google's `run_deepvariant` against `pbrun deepvariant` v4.7.1, using `AUS/DOCs/issues/issues_83/pbrun_deepvariant.csv` as the parameter source of truth.

## CPU command

```bash
/opt/deepvariant/bin/run_deepvariant \
  --ref=reference.fa --reads=sample.bam \
  --output_vcf=sample.deepvariant.vcf.gz \
  --output_gvcf=sample.deepvariant.g.vcf.gz \
  --regions=intervals.bed \
  --intermediate_results_dir=tmp \
  --num_shards=8
```

Ref: [issue-83](https://github.com/NAICNO/accelerated_genomics/issues/83)

---

## 1. Parameter mapping table

| CPU param (`run_deepvariant`) | CPU value | Parabricks deepvariant equivalent | Notes |
|---|---|---|---|
| `--model_type` | **not set in above issue-83 command** | `--mode MODE` (`shortread`/`pacbio`/`ont`, default `shortread`) + `--use-wes-model` | Current DeepVariant releases require `--model_type` |
| `--ref` | `reference.fa` | `--ref REF` | |
| `--reads` | `sample.bam` | `--in-bam IN_BAM` | |
| `--output_vcf` | `sample.deepvariant.vcf.gz` | `--out-variants OUT_VARIANTS` | Allows vcf/vcf.gz/g.vcf/g.vcf.gz (per Parabricks docs), smoke tests accepted `.vcf.gz`, unlike haplotypecaller. |
| `--output_gvcf` | `sample.deepvariant.g.vcf.gz` | `--gvcf` flag + `--out-variants <name>.g.vcf[.gz]` | Parabricks writes the gVCF to `--out-variants` and **also** a same-named `.vcf` alongside it |
| `--regions` | `intervals.bed` | `--interval-file INTERVAL_FILE` (BED only) or `-L` | Direct match for BED. |
| `--intermediate_results_dir` | `tmp` | `--tmp-dir TMP_DIR` + `--keep-tmp` |  |
| `--num_shards` | `8` | `--num-cpu-threads-per-stream` (default 6), `--num-streams-per-gpu` (default auto), `--num-gpus` (default 1), `--run-partition`, `--partition-size`, `--max-reads-per-partition` | No 1:1 |

## 2. Parabricks-only parameters with no CPU-command equivalent

Performance/runtime: `--num-cpu-threads-per-stream`, `--num-streams-per-gpu`, `--run-partition`, `--gpu-num-per-partition`, `--max-reads-per-partition`, `--partition-size`, `--use-tf32`, `--prealign-helper-thread`, `--num-gpus`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`.

Model/algorithm options not used by the CPU command (leave at defaults for parity): `--pb-model-file`, `--pb-small-model-file`, `--proposed-variants`, `--variant-caller`, `--disable-use-window-selector-model`, `--sort-by-haplotypes`, `--add-hp-channel`, `--parse-sam-aux-fields`, `--phase-reads`, `--alt-aligned-pileup`, `--normalize-reads`, `--track-ref-reads`, `--haploid-contigs`, `--create-complex-alleles`, `--multiallelic-mode`, `--include-med-dp`, the various `--channel-*`/`--skip-bq-channel` options, and the flow-sequencing/Ultima options (`--vsc-min-fraction-hmer-indels`, `--vsc-turn-on-non-hmer-ins-proxy-support`, `--channel-ins-size`, `--max-ins-size`).

## 3. CPU parameters with no Parabricks equivalent

- `--intermediate_results_dir` (closest: `--tmp-dir` + `--keep-tmp`)
- `--model_type` as a single enum (split into `--mode` + `--use-wes-model`; some types unmapped)
- `--num_shards`
