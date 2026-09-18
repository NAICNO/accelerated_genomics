# CPU → Parabricks Parameter Mapping: fq2bam v4.7.1

- Covers the CPU-based somatic-pipeline steps `bwa mem` → `gatk MarkDuplicates` → `gatk BaseRecalibrator`
- Parameter mapping table use parameters in file - [`pbrun fq2bam` v4.7.1](pbrun_fq2bam.csv) as source of truth for CPU- to PB-run command mappings

---

## CPU-based command

1. bwa mem

```bash
# For tumor sample
bwa mem \
        -K 100000000 -Y -B 3 -R ${meta.read_group} \
        -t $task.cpus \
        $INDEX \ # genome reference index file path
        $reads \ # the paired-end reads path

# For normal control
bwa mem \
        -K 100000000 -Y -R ${meta.read_group} \
        -t $task.cpus \
        $INDEX \ # genome reference index file path
        $reads \ # the paired-end reads path
```

2. GATK markduplicate

```bash
gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \
        MarkDuplicates \
        --INPUT $bam \ # input bam file path if (there are multiple lane for bam file, users have to list all of them with a space as the separator 
        --OUTPUT ${prefix_bam} \ # output bam file path
        --METRICS_FILE ${prefix}.metrics \
        --REMOVE_DUPLICATES false \
        --CREATE_INDEX true \
        --TMP_DIR /tmp \
        --reference ${reference} \ # the path of genome reference 
```

3. GATK BaseRecalibrator

```bash
gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \
        BaseRecalibrator  \
        --input ${input} \ # the path of input bam file
        --output ${prefix}.table \ # output the BaseRecalibrator table
        --reference ${fasta} \ # the path of genome reference
        --intervals $intervals \ # genome interval bed file for WGS which is available in GATK bundle data. If it is exome-seq data, users have to prepare for the targeted interval file by themselves.
        --known-sites $vcf \ #known snp source data (e.g., dbsnp, 1000 genome) which are available in GATK bundle data.
        --tmp-dir /tmp \
```

## 1. Parameter mapping table

### 1a. `bwa mem` → `fq2bam`

| CPU param | CPU value used | Parabricks fq2bam equivalent | Notes |
|---|---|---|---|
| `-K` | `100000000` | `--bwa-options="-K 100000000"` | `-K` is in fq2bam's supported bwa-options passthrough list |
| `-Y` | (tumor + normal) | `--bwa-options="-Y"` | Supported passthrough. Use soft-clipping for supplementary alignments (matches bwa's default-off `-Y` behavior CPU-side). |
| `-B 3` | tumor only (normal uses bwa's default `-B 4`) | `--bwa-options="-B 3"` | Supported passthrough. **Only for the tumor sample's fq2bam invocation** — production script is asymmetric (tumor gets a lower mismatch penalty, normal uses bwa's built-in default of 4) |
| `-R ${meta.read_group}` | full `@RG` string | **No direct `--bwa-options` equivalent** — `-R` is *not* in fq2bam's supported passthrough list. **fq2bam RG mechanism:** set `--read-group-sm`, `--read-group-lb`, `--read-group-pl`, `--read-group-id-prefix` | `fq2bam`'s RG mechanism is a required behavior change, not optional. `fq2bam` was found defaulting every BAM's `SM` tag to the literal string when `--read-group-sm` wasn't set |
| `-t $task.cpus` | cluster-assigned | **No direct equivalent.** | bwa mem's CPU threading is superseded by GPU alignment. Closest tunables are performance knobs, not a 1:1 mapping: `--num-gpus`, `--bwa-nstreams`, `--bwa-cpu-thread-pool`/`--num-cpu-threads-per-stage`, `--bwa-primary-cpus`, `--bwa-normalized-queue-capacity`. Tune GPU/CPU work distribution, not thread count for a CPU-bound aligner. |
| `$INDEX` (bwa index path) | genome ref index | `--ref REF` | fq2bam takes the FASTA reference directly (with co-located `.fai`/`.dict`/bwa index files expected alongside it) |
| `$reads` (paired FASTQ) | R1/R2 paths | `--in-fq [IN_FQ ...]` (or `--in-fq-list` for many pairs) | Multi-lane handling differs |

### 1b. `gatk MarkDuplicates` → `fq2bam`

| CPU param | CPU value used | Parabricks fq2bam equivalent | Notes |
|---|---|---|---|
| `--INPUT` (repeatable for multi-lane) | 1+ BAMs | *(implicit — fq2bam consumes FASTQ directly, no separate merge step)* | Multi-lane merge mechanism differs |
| `--OUTPUT` | `${prefix_bam}` | `--out-bam OUT_BAM` | |
| `--METRICS_FILE` | `${prefix}.metrics` | `--out-duplicate-metrics OUT_DUPLICATE_METRICS` | |
| `--REMOVE_DUPLICATES false` | (explicit) | *No flag* | fq2bam has no option to remove duplicates outright, only mark them. Functionally consistent with the CPU command's explicit `false` |
| `--CREATE_INDEX true` | (explicit) | *(implicit — fq2bam always emits an index for the output BAM/CRAM)* | |
| `--TMP_DIR /tmp` | | `--tmp-dir TMP_DIR` | |
| `--reference` | | `--ref REF` (shared with alignment) | |
| *(not set)* | | `--markdups-picard-version-2182` | Off by default. See §2 — the duplicate-marking algorithm is not guaranteed identical to current Picard/GATK MarkDuplicates even with this flag set. |

### 1c. `gatk BaseRecalibrator` → `fq2bam`

| CPU param | CPU value used | Parabricks fq2bam equivalent | Notes |
|---|---|---|---|
| `--input` | BAM from MarkDuplicates | *(implicit — same fused BAM stream, if using `--standalone-bqsr`/`--out-recal-file` inside the same fq2bam call)* | Only applicable if you fuse BQSR-table generation into fq2bam itself; this pipeline instead runs it as separate module `bqsr.nf` per the repo's architecture. |
| `--output` | `${prefix}.table` | `--out-recal-file OUT_RECAL_FILE` | |
| `--reference` | | `--ref REF` (shared) | |
| `--intervals` | interval BED/list | `--interval-file INTERVAL_FILE` (or `-L`/`--interval` for ad hoc intervals) | |
| `--known-sites` (repeatable) | dbSNP/1000G VCFs | `--knownSites KNOWNSITES` (repeatable) | Naming/casing differs (`--known-sites` vs `--knownSites`) — trivial but worth a lint check in scripts that build flags programmatically. |
| `--tmp-dir /tmp` | | `--tmp-dir TMP_DIR` (shared) | |

---

## 3. Parabricks-only parameters with no CPU equivalent

Performance/GPU-acceleration knobs that don't correspond to any CPU-side flag

`--max-read-length-on-gpu`, `--bwa-nstreams`, `--bwa-cpu-thread-pool`/`--num-cpu-threads-per-stage`, `--bwa-normalized-queue-capacity`, `--bwa-primary-cpus`, `--cigar-on-gpu`, `--run-partition`, `--bwa-gpu-num-per-partition`, `--gpuwrite`, `--gpuwrite-deflate-algo`, `--gpusort`, `--use-gds`, `--memory-limit`, `--low-memory`, `--num-gpus`, `--with-petagene-dir`, `--monitor-usage`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--keep-tmp`, `--no-warnings`, `--verbose`, `--logfile`.

---
