# CPU → Parabricks Parameter Mapping: applybqsr v4.7.1

Covers `gatk ApplyBQSR` against `pbrun applybqsr` v4.7.1, using `docs/cpu_2_pbrun_mappings/pbrun_applybqsr.csv` as the parameter source of truth. This is a close 1:1 tool pair (no fusion), so the risk sits in two CPU flags with no Parabricks equivalent and in defaults the CPU command leaves implicit.

CPU command compared:

```bash
gatk --java-options "-Xmx3072M -XX:-UsePerfData" ApplyBQSR \
  --input sample.bam --output sample.recalibrated.bam --reference reference.fa \
  --bqsr-recal-file sample.table --tmp-dir . \
  --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30 \
  --create-output-bam-md5 true
```

Current Nextflow module (`modules/applybqsr.nf`) calls `pbrun applybqsr` with only `--ref`, `--in-bam`, `--in-recal-file`, optional interval args, `--out-bam`, `--num-gpus`.

---

## 1. Parameter mapping table

| CPU param (`gatk ApplyBQSR`) | CPU value | Parabricks applybqsr equivalent | Notes |
|---|---|---|---|
| `--input` | `sample.bam` | `--in-bam IN_BAM` | |
| `--output` | `sample.recalibrated.bam` | `--out-bam OUT_BAM` | |
| `--reference` | `reference.fa` | `--ref REF` | |
| `--bqsr-recal-file` | `sample.table` | `--in-recal-file IN_RECAL_FILE` | Required in Parabricks. |
| `--tmp-dir` | `.` | `--tmp-dir TMP_DIR` (default `.`) | Same default. |
| `--static-quantized-quals 10/20/30` | three bins | **No equivalent in the CSV** | **Clinically relevant — see §2.1.** |
| `--create-output-bam-md5 true` | on | **No equivalent** | See §2.2. |
| `--java-options "-Xmx3072M -XX:-UsePerfData"` | JVM heap/flags | **No equivalent (JVM-specific)** | Closest knobs are `--num-threads` (default 8) and `--num-gpus` (default 1); neither is a memory limit. |
| *(not set)* `--intervals` | whole BAM | `--interval-file` / `-L` / `-ip` (optional) | CPU command processes the whole BAM. See §2.4. |

---

## 2. Default/behavioral differences flagged for clinical review

1. **`--static-quantized-quals` has no Parabricks equivalent, so output base qualities will differ.** The CPU command bins recalibrated base qualities into a few static levels (10/20/30). `pbrun applybqsr` exposes no such option, and the repo's `applybqsr.nf` passes none, so the GPU BAM carries unbinned recalibrated qualities. Mutect2, HaplotypeCaller, DeepVariant and DeepSomatic all consume base qualities, so this is a systematic input difference, not a cosmetic one. It is also not fixable by a flag: matching it would need a downstream binning step or a decision that the CPU command is the one to change. Decide explicitly which is the clinical reference, and confirm with `pbrun applybqsr --help` for v4.7.1 that the option really is absent. If the collaborator's pipeline needs the binned form, concordance results for every downstream caller should be interpreted with this in mind.

2. **No MD5 output.** `--create-output-bam-md5 true` writes a checksum of the BAM bytes. Parabricks has no such flag, and a byte-level checksum could not be compared across CPU and GPU runs anyway (different writers, different binning per §2.1). Generate checksums externally (`md5sum`) for file-integrity purposes only, and compare CPU vs GPU BAMs by content (e.g. `samtools view` record comparison, base-quality distributions), not by checksum.

3. **Unstated GATK defaults that the CPU command silently relies on — verify the Parabricks behavior matches.** None are exposed in the CSV:
   - `--preserve-qscores-less-than` (GATK default 6: bases below Q6 are left unrecalibrated).
   - `--use-original-qualities` / `--emit-original-quals` (GATK default off: no OQ tag written).
   - Output index creation (GATK writes a `.bai` by default); the CSV does not say whether `pbrun applybqsr` does.
   - SAM `@PG` program record (GATK adds one by default); version-provenance checks that grep `@PG` lines (per the version-verification runbook) depend on Parabricks adding its own.

4. **Interval handling.** The CPU command is unrestricted. `pbrun applybqsr` interval options (`--interval-file`, `-L`) pad by 100 bp by default and restrict which reads are processed, so reads outside the intervals are not in the output BAM. The repo's exome design applies this deliberately for WES; for WGS (no interval args) behavior should match the CPU command. Keep the interval choice identical on both sides when benchmarking.

5. **Recal table provenance.** Parabricks `applybqsr` is normally fed a table from `pbrun fq2bam`/`bqsr`, the CPU command from GATK `BaseRecalibrator`. If cross-feeding tables to isolate the ApplyBQSR step, confirm Parabricks accepts GATK-format tables from the CPU side; the CSV does not state this.

6. **Threading/memory are not equivalent knobs.** `-Xmx3072M` bounds JVM heap; `--num-threads` (default 8) sets worker threads. Do not carry the 3 GB figure over as a sizing hint for the `APPLYBQSR` resource profile.

---

## 3. Parabricks-only parameters with no CPU-command equivalent

`--num-threads`, `--num-gpus`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`, `--version`, `-ip/--interval-padding`. All are performance/runtime or interval controls; none change results when left at defaults (apart from intervals, §2.4).

## 4. CPU parameters with no Parabricks equivalent

- `--static-quantized-quals` (×3) — §2.1, clinically relevant
- `--create-output-bam-md5` — §2.2
- `--java-options` (`-Xmx`, `-XX:-UsePerfData`) — JVM only

---

*Generated 2026-10-05 from `pbrun_applybqsr.csv` (Parabricks v4.7.1) and the provided GATK ApplyBQSR command. Side note: `docs/cpu_2_pbrun_mappings/mutectcaller_cpu_to_pbrun_mapping.csv` appears to be a copy of `pbrun_mutectcaller.csv` rather than a mapping table.*
