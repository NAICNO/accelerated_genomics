# CPU → Parabricks Parameter Mapping: haplotypecaller v4.7.1

Covers `gatk HaplotypeCaller` against `pbrun haplotypecaller` v4.7.1, using `AUS/DOCs/issues/issues_82/pbrun_haplotypecaller.csv` as the parameter source of truth.

## CPU command

```bash
gatk --java-options "-Xmx3072M -XX:-UsePerfData" \
  HaplotypeCaller \
  --input sample.bam \
  --output sample.haplotypecaller.vcf.gz \
  --reference reference.fa 
  --max-alternate-alleles 3 \
  --read-filter OverclippedReadFilter \
  --dbsnp dbsnp.vcf.gz \
  --intervals intervals.bed \
  --tmp-dir .  
```

---

## 1. Parameter mapping table

| CPU param (`gatk HaplotypeCaller`) | CPU value | Parabricks haplotypecaller equivalent | Notes |
|---|---|---|---|
| `--input` | `sample.bam` | `--in-bam IN_BAM` | Parabricks also accepts a folder of BAMs. |
| `--output` | `sample.haplotypecaller.vcf.gz` | `--out-variants OUT_VARIANTS` | The CSV says vcf/vcf.gz are allowed, but initial smoketests rejected `.vcf.gz` ("Output file name should be .vcf") |
| `--reference` | `reference.fa` | `--ref REF` | |
| `--max-alternate-alleles` | `3` | `--max-alternate-alleles MAX_ALTERNATE_ALLELES` | Direct match |
| `--read-filter OverclippedReadFilter` | enabled | **No equivalent** | Parabricks can only *disable* four named filters (`--disable-read-filter`) |
| `--dbsnp` | `dbsnp.vcf.gz` | **No equivalent** | Annotation only. (GATK HC populates the VCF ID column and `DB` flag without affecting VC. Parabricks output will have no rsIDs) |
| `--intervals` | `intervals.bed` | `--interval-file INTERVAL_FILE` (BED supported) or `-L` | Parabricks `-L` intervals get a padding of 100 to fetch reads, need to verify if this is the case in `--interval-file` as well |
| `--tmp-dir` | `.` | `--tmp-dir TMP_DIR` (default `.`) | Same default. |
| `--java-options "-Xmx3072M -XX:-UsePerfData"` | JVM heap/flags | **No equivalent (JVM only)** | Not a sizing hint for the GPU job. |

---

## 2. Parabricks-only parameters with no CPU-command equivalent

Performance/runtime: `--htvc-low-memory`, `--num-htvc-threads` (default 5), `--num-streams-per-gpu` (default 1), `--run-partition`, `--gpu-num-per-partition`, `--num-gpus`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`.

Functional, not used by the CPU command (leave unset): `--gvcf`, `-GQB`, `--rna`, `--htvc-alleles`, `--htvc-bam-output`, `--disable-read-filter`, `--force-call-filtered-alleles`, `--filter-reads-too-long`, `--no-alt-contigs`, `-XL`, `-G`, `--haplotypecaller-options`, `--in-recal-file`, `--static-quantized-quals`.

## 4. CPU parameters with no Parabricks equivalent

- `--read-filter OverclippedReadFilter` — affects which reads are used
- `--dbsnp` — annotation only
- `--java-options` — JVM only
