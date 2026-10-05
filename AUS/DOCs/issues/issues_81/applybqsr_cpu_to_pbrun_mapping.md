# CPU → Parabricks Parameter Mapping: applybqsr v4.7.1

Covers `gatk ApplyBQSR` against `pbrun applybqsr` v4.7.1, using `AUS/DOCs/issues/issues_81/pbrun_applybqsr.csv` as the parameter source of truth.

## CPU command compared

```bash
gatk --java-options "-Xmx3072M -XX:-UsePerfData" ApplyBQSR \
  --input sample.bam --output sample.recalibrated.bam --reference reference.fa \
  --bqsr-recal-file sample.table --tmp-dir . \
  --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30 \
  --create-output-bam-md5 true
```

---

## 1. Parameter mapping table

| CPU param (`gatk ApplyBQSR`) | CPU value | Parabricks applybqsr equivalent | Notes |
|---|---|---|---|
| `--input` | `sample.bam` | `--in-bam IN_BAM` | |
| `--output` | `sample.recalibrated.bam` | `--out-bam OUT_BAM` | |
| `--reference` | `reference.fa` | `--ref REF` | |
| `--bqsr-recal-file` | `sample.table` | `--in-recal-file IN_RECAL_FILE` | Required in Parabricks. |
| `--tmp-dir` | `.` | `--tmp-dir TMP_DIR` (default `.`) | Same default. |
| `--static-quantized-quals 10/20/30` | three bins | **No equivalent in the CSV** |  With `--static-quantized-quals` left at its default, resulting quality scores from the two tools should be close, but can't confirm that they are identical |
| `--create-output-bam-md5 true` | on | **No equivalent** |  |
| `--java-options "-Xmx3072M -XX:-UsePerfData"` | JVM heap/flags | **No equivalent (JVM-specific)** | Closest knobs are `--num-threads` (default 8) and `--num-gpus` (default 1); neither is a memory limit. |
| `--intervals` | whole BAM | `--interval-file` / `-L` / `-ip` (optional) | CPU command processes the whole BAM. See §2.4. |

---

## 2. Parabricks-only parameters with no CPU-command equivalent

`--num-threads`, `--num-gpus`, `--with-petagene-dir`, `--keep-tmp`, `--no-seccomp-override`, `--preserve-file-symlinks`, `--verbose`, `--logfile`, `--version`, `-ip/--interval-padding`. All are performance/runtime or interval controls

## 3. CPU parameters with no Parabricks equivalent

- `--static-quantized-quals` (×3) — §2.1, clinically relevant
- `--create-output-bam-md5` — §2.2
- `--java-options` (`-Xmx`, `-XX:-UsePerfData`) — JVM only
