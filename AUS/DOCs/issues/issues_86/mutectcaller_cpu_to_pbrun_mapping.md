# CPU → Parabricks Parameter Mapping: mutectcaller v4.7.1

- Covers the CPU-based somatic-pipeline `gatk Mutect2` (tumor-normal and tumor-only)
- Parameter mapping table ($1) use parameters in file - [`pbrun mutectcaller` v4.7.1](mutectcaller_cpu_to_pbrun_mapping.csv) as source of truth for CPU- to PB-run command mappings

## CPU-based command

```bash
# Tumor-Normal in pair

gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \
        Mutect2 \
        --input $tumor \ # path of tumor bam file
        --input $normal \ # path of normal bam file
        --normal-sample ${normal}_sample_name \ # the name of normal control
        --f1r2-tar-gz ${task.ext.prefix}.f1r2.tar.gz \
        --output ${prefix}.vcf.gz \ # the path of output vcf file
        --reference ${fasta} \ # the path of genome reference
        --panel-of-normals ${pon} \ # panel of normal controls if users have multiple normal control available (users have to prepare this file by themselves)
        --germline-resource ${gr} \ # germline resource which is available in GATK bundle
        --intervals ${interval} \  # genome interval bed file for WGS which is available in GATK bundle data. If it is exome-seq data, users have to prepare for the targeted interval file by themselves.
        --tmp-dir /tmp

# Tumor-only

gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \
        Mutect2 \
        --input $tumor \ # path of tumor bam file
        --f1r2-tar-gz ${task.ext.prefix}.f1r2.tar.gz \
        --output ${prefix}.vcf.gz \ # the path of output vcf file
        --reference ${fasta} \ # the path of genome reference
        --panel-of-normals ${pon} \ # panel of normal controls if users have multiple normal control available (users have to prepare this file by themselves)
        --germline-resource ${gr} \ # germline resource which is available in GATK bundle
        --intervals ${interval} \  # genome interval bed file for WGS which is available in GATK bundle data. If it is exome-seq data, users have to prepare for the targeted interval file by themselves.
        --tmp-dir /tmp
```

---

## 1. Parameter mapping table

| CPU param (`gatk Mutect2`) | CPU value used | Parabricks mutectcaller equivalent | Notes |
|---|---|---|---|
| `--input $tumor` | tumor BAM | `--in-tumor-bam IN_TUMOR_BAM` | |
| `--input $normal` | normal BAM (T/N mode only) | `--in-normal-bam IN_NORMAL_BAM` | Omit for tumor-only mode, same as CPU. |
| *tumor-name* Not set| | `--tumor-name TUMOR_NAME` | GATK Mutect2 auto-detects tumor sample name from BAM `SM` tag, Parabricks requires `--normal-sample` (no auto-detection in `pbrun`)|
| `--normal-sample` | normal sample name | `--normal-name NORMAL_NAME` | Must match the normal BAM's `SM` tag exactly, same as GATK has for `--normal-sample`. |
| `--f1r2-tar-gz` | `${task.ext.prefix}.f1r2.tar.gz` | `--mutect-f1r2-tar-gz MUTECT_F1R2_TAR_GZ` | |
| `--output ${prefix}.vcf.gz` | output VCF | `--out-vcf OUT_VCF` | |
| `--reference` | | `--ref REF` | |
| `--panel-of-normals ${pon}` | PON vcf.gz | `--pon PON` | CPU `--panel-of-normals` passes the combined PON-VCF; Parabricks expects Path of the vcf.gz PON file (`pbrun prepon`-processed artifact) |
| `--germline-resource ${gr}` | germline resource vcf.gz | `--mutect-germline-resource MUTECT_GERMLINE_RESOURCE` | |
| `--intervals ${interval}` | interval BED/list | `--interval-file INTERVAL_FILE` (or `-L`/`--interval` for ad hoc) | |
| `--tmp-dir /tmp` | | `--tmp-dir TMP_DIR` | |

---

## 3. Parabricks-only parameters with no CPU-command equivalent

Performance/GPU tuning, not clinically relevant on their own: `--mutect-low-memory`, `--run-partition`, `--gpu-num-per-partition`, `--num-htvc-threads` (default: 5), `--num-streams-per-gpu` (default: 1), `--num-gpus`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`.

## 4. Functional flags not exercised by the CPU command

**Worth a deliberate on/off decision rather than silent default:**

- `--mutect-alleles` (force-call sites) / `--force-call-filtered-alleles` — not used CPU-side
- `--filter-reads-too-long` — drops reads >500bp; not present CPU-side (by default either)
- `-ip`/`--interval-padding` — CPU command doesn't pad intervals beyond whatever's baked into the interval file itself (leave unset to match)

---
