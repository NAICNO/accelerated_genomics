# CPU (Google DeepSomatic) → Parabricks Parameter Mapping: deepsomatic v4.7.1

- Covers Google's reference `run_deepsomatic` Docker command against `pbrun deepsomatic` v4.7.1, [using `pbrun_deepsomatic.csv`](pbrun_deepsomatic.csv)

---

## 1. Parameter mapping table

| Google `run_deepsomatic` param | Value in reference command | Parabricks deepsomatic equivalent | Notes |
|---|---|---|---|
| `--model_type=` | one of `WGS/WES/PACBIO/ONT/FFPE_WGS/FFPE_WES/WGS_TUMOR_ONLY/PACBIO_TUMOR_ONLY/ONT_TUMOR_ONLY` | `--mode MODE` (`shortread`/`pacbio`/`ont`, default `shortread`) **+** `--use-wes-model` (boolean) | **Not a clean 1:1** Google folds sequencing platform, exome-vs-genome, FFPE-vs-fresh, and tumor-only-vs-paired into one enum. Parabricks splits platform+exome into two flags and has **no FFPE or tumor-only equivalent** |
| `--ref` | reference FASTA | `--ref REF` | |
| `--reads_normal` | normal BAM | `--in-normal-bam IN_NORMAL_BAM` | **Required** - **Tumor-only mode may not be supported at all — this is the item to confirm first.** |
| `--reads_tumor` | tumor BAM | `--in-tumor-bam IN_TUMOR_BAM` |  |
| `--output_vcf` | final VCF path | `--out-variants OUT_VARIANTS` | Accepting `vcf/vcf.gz/g.vcf/g.vcf.gz` |
| `--output_gvcf` | gVCF path | Same `--out-variants` (Need to verify gVCF output) | |
| `--sample_name_tumor` / `--sample_name_normal` | `"tumor"` / `"normal"` | **No equivalent flag found in the CSV.** | Presumably taken from BAM `SM` tags with no override, unlike Google's explicit naming. |
| `--num_shards=$(nproc)` | CPU thread count | `--num-cpu-threads-per-stream` (default 6), `--num-streams-per-gpu` (default `auto`), `--num-gpus` (default 1), `--run-partition`/`--gpu-num-per-partition`/`--partition-size` | Not a 1:1 mapping |
| `--intermediate_results_dir` | debug/intermediate output dir | **No equivalent flag.** | Closest available knobs are `--tmp-dir TMP_DIR` + `--keep-tmp` |
| `--regions=chr1` | region restriction | `--interval-file INTERVAL_FILE` (BED) or `-L`/`--interval` (repeatable) | `--interval-file`, with `-L`/`--interval` for ad hoc string-style intervals (e.g. `-L chr1`). |
| `--use_default_pon_filtering=false` | tumor-only PON filtering toggle | **No equivalent flag found.** | Flag only makes sense in Google's tumor-only mode, which doesn't appear to have a Parabricks counterpart |

---

## 3. Parabricks-only parameters with no Google-command equivalent

Performance/GPU tuning: `--num-cpu-threads-per-stream`, `--num-streams-per-gpu`, `--num-gpus`, `--run-partition`, `--gpu-num-per-partition`, `--partition-size`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`.

---

## 4. Google-command parameters with no Parabricks equivalent (recap)

- `--sample_name_tumor` / `--sample_name_normal`
- `--intermediate_results_dir` (no documented equivalent)
- `--use_default_pon_filtering` (tumor-only-specific)
- `--dry_run` (§2.5)
- FFPE model selection via `--model_type=FFPE_WGS`/`FFPE_WES`
- Tumor-only model types (`WGS_TUMOR_ONLY`/`PACBIO_TUMOR_ONLY`/`ONT_TUMOR_ONLY`)

---

