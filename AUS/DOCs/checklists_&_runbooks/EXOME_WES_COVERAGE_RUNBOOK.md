# Runbook & Checklist: WES Germline & Somatic End-to-End Smoke Test

## Run metadata

| Field | Value |
|-------|-------|
| Date tested | |
| Tested by | |
| Cluster(s) | ☐ Fox  ☐ TSD |
| Pipeline commit/revision | |
| Parabricks container | `clara-parabricks_4.7.1-1.sif` (confirm path) |
| `nextflow` version | |
| `-profile` used | `singularity,<fox\|tsd>,<production\|test>` |
| Source data | [GitHub: issue#]() |
| `interval_file` used | (e.g. `GRCh38_chr21_intervals.bed` — record path + how it was derived) |
| Parameters | |

## Goal

Confirm WES support on real cluster infrastructure

1. `--interval-file` reaches `bqsr`, `applybqsr`, `haplotypecaller`, `mutectcaller`,
   `deepvariant`, `deepsomatic` — and reaches none of `fq2bam`.
2. `--use-wes-model` is auto-derived correctly for both `deepvariant` and `deepsomatic` when
   `sequencing_type=wes` and the tool's own `*_mode` is `shortread` (default) — and correctly
   *absent* when `*_mode` is `pacbio`/`ont`.
3. `--mode ${params.*_mode}` is passed unconditionally and symmetrically by both callers.
4. Fail-fast validation actually fires on a real invocation, not just in the local smoke test.
5. Restriction is real, not just smaller-looking: no variant calls land outside the target
   BED.
6. The params file used matches the current `params.*.yaml.example` — no stale/removed keys
   left over from a prior design (e.g. the removed `deepsomatic_model_type`).

## Prerequisites

- [ ] Real (or realistically-sized) exome BED file available and path recorded above
- [ ] `params.germline_wes.yaml` / `params.somatic_wes.yaml` regenerated from the **current**
      `params.germline.yaml.example` / `params.somatic.yaml.example` — diff them first:
      `diff <(grep -v '^#' params.germline.yaml.example) <(grep -v '^#' params.germline_wes.yaml)`
      (and same for somatic) — resolve any stale key before running
- [ ] A comparable WGS run's outputs available for the same sample(s), for the size/count
      comparison (e.g. `results_germline_4.7.1/`, `results_somatic_v4.7.1/`)
- [ ] SLURM/GPU allocation available on the target cluster(s)

---

## 1. Germline pipeline

### 1a. Run

- [ ] Exact run command recorded (copy-pasteable)
- [ ] `-profile` recorded
- [ ] Run started / completed timestamps, wall-clock duration, CPU hours
- [ ] Exit status confirmed (0 / success, all tasks ✔)

**Run command:**

```bash

```

**Terminal output:**

```none

```

### 1b. Fail-fast validation (real-cluster spot check)

Run each of these as a deliberate one-off (expect immediate failure, before any process is
scheduled — confirm no SLURM job is submitted):

- [ ] `--sequencing_type wes` with no `--interval_file` → errors
- [ ] `--interval_file <path>` with `--sequencing_type wgs` (default) → errors
- [ ] Invalid `--sequencing_type` value → errors

```bash
# paste the three commands + their error output here
```

### 1c. Direct command-line evidence (not just output-size inference)

Pull the actual resolved `pbrun` command line for each task from `.command.sh` in the task's
work directory (path is in the Nextflow log, e.g. `[a5/3e9489]` → `work/a5/3e9489*/.command.sh`),
or from `results/pipeline_info/trace.txt` if it captures the full command.

- [ ] `FQ2BAM` — confirm **no** `--interval-file` present
- [ ] `BQSR` — confirm `--interval-file <path>` present
- [ ] `APPLYBQSR` — confirm `--interval-file <path>` present
- [ ] `HAPLOTYPECALLER` — confirm `--interval-file <path>` present
- [ ] `DEEPVARIANT` — confirm `--interval-file <path>`, `--mode shortread`, and
      `--use-wes-model` all present

```bash
# grep .command.sh for each task, paste matching lines here
```

### 1d. Negative-mode case (optional but recommended for full symmetry coverage)

- [ ] Re-run `DEEPVARIANT` alone (or a minimal re-run) with `--deepvariant_mode pacbio` and
      confirm the resolved command shows `--mode pacbio` and **no** `--use-wes-model`

```bash

```

### 1e. Output comparison vs. WGS baseline

- [ ] `bam/` sizes ~equal between WES and WGS run (confirms `fq2bam` unrestricted)
- [ ] `bam_recal/` sizes substantially smaller for WES (confirms BQSR/APPLYBQSR restriction)
- [ ] Variant counts (`grep -cv "#" *.vcf`) substantially lower for WES, both callers

```none
# tree -h / grep -cv "#" output, WES vs WGS, both callers
```

### 1f. Off-target spot-check (the part size/count comparisons don't prove)

- [ ] `bedtools intersect -v` (or equivalent) of each WES output VCF against `interval_file`
      returns **zero** records — i.e. every call is inside the target regions

```bash
bedtools intersect -v -a results_germline_wes/vcf/deepvariant/SAMPLE01.deepvariant.vcf \
  -b <interval_file>.bed | grep -cv "#"
# expect: 0

bedtools intersect -v -a results_germline_wes/vcf/haplotypecaller/SAMPLE01.haplotypecaller.vcf \
  -b <interval_file>.bed | grep -cv "#"
# expect: 0
```

### 1g. Logs

- [ ] Work-dir logs captured (`.command.sh`/`.command.log`/`.exitcode`) for at least the tasks
      checked in 1c, per the `rsync --include='.command*'` pattern used in
      `Pipeline_Testing_Checklist.md`

---

## 2. Somatic pipeline

### 2a. Run

- [ ] Exact run command recorded
- [ ] `-profile` recorded
- [ ] Run started / completed timestamps, wall-clock duration, CPU hours
- [ ] Exit status confirmed (0 / success, all tasks ✔)

**Run command:**

```bash

```

**Terminal output:**

```none

```

### 2b. Fail-fast validation (real-cluster spot check)

- [ ] Same three checks as 1b, run against `somatic_main.nf`

```bash

```

### 2c. Direct command-line evidence

- [ ] `FQ2BAM` (tumor + normal) — confirm **no** `--interval-file`
- [ ] `BQSR` / `APPLYBQSR` (tumor + normal) — confirm `--interval-file <path>`
- [ ] `MUTECTCALLER` — confirm `--interval-file <path>`
- [ ] `DEEPSOMATIC` — confirm `--interval-file <path>`, `--mode shortread`, and
      `--use-wes-model` all present

```bash

```

### 2d. Negative-mode case

- [ ] Re-run `DEEPSOMATIC` with `--deepsomatic_mode pacbio`, confirm `--mode pacbio` and
      **no** `--use-wes-model`

```bash

```

### 2e. Output comparison vs. WGS baseline

- [ ] `bam/` sizes ~equal between WES and WGS (tumor + normal)
- [ ] `bam_recal/` sizes substantially smaller for WES (tumor + normal)
- [ ] `mutect2` and `deepsomatic` VCF variant counts substantially lower for WES

```none

```

### 2f. Off-target spot-check

- [ ] `bedtools intersect -v` of `mutect2` filtered VCF against `interval_file` → zero records
- [ ] `bedtools intersect -v` of `deepsomatic` VCF against `interval_file` → zero records

```bash

```

### 2g. `NO_FILE_INTERVAL` / `NO_FILE_PON` collision (blocked — see open items doc)

- [ ] **Not runnable yet.** Exercising the real double-`NO_FILE` case (both `pon` and
      `interval_file` unset on the same `MUTECTCALLER` task) requires the pon workflow input
      to be wired alongside `interval_file` in a real run — today's params files always set
      `interval_file` when testing WES, so `pon` is the only `NO_FILE` present. Leave unchecked
      until the `MUTECTCALLER_STUB` extension (section 11 item 5) lands and the corresponding
      local test is added; note here if a real-cluster run happens to exercise the double-unset
      case incidentally.

### 2h. Logs

- [ ] Work-dir logs captured for at least the tasks checked in 2c

---

## 3. Params-file hygiene

- [ ] `params.germline_wes.yaml` diffed against current `params.germline.yaml.example` —
      no keys present that the example doesn't document
- [ ] `params.somatic_wes.yaml` diffed against current `params.somatic.yaml.example` — no
      keys present that the example doesn't document (specifically: confirm no leftover
      `deepsomatic_model_type` — that param was removed from `somatic.config` on 2026-09-10
      and no longer does anything)

```bash

```

---

## 4. Cross-cluster check (Fox vs. TSD)

- [ ] Both pipelines run with the same `interval_file` / sample(s) on **both** Fox and TSD
- [ ] Runtime and CPU-hours recorded for both, compared
- [ ] No cluster-specific config gotchas re-triggered (stray characters, bare `def`,
      `--mem`/`--mem-per-cpu` conflict — see project memory for the closed incidents)

| Pipeline | Cluster | Duration | CPU hours | Exit status |
|---|---|---|---|---|
| Germline | Fox | | | |
| Germline | TSD | | | |
| Somatic | Fox | | | |
| Somatic | TSD | | | |

---

## 5. Summary

- [ ] Overall pass/fail for full WES coverage (both pipelines, all six checks in section 0's
      Goal list)
- [ ] Any gap found here fed back into `EXOME_OPEN_ITEMS.md` (or closed out there, if this run
      resolves it)

## Sign-off

- [ ] All checks above passed — WES support qualified as fully verified on real cluster data
- Signed off by: ______, date: ______

## Notes / gotchas

- `-resume` can make a run "succeed" without re-executing the tasks you actually changed —
  do a fresh run (or clear the relevant `work/` dirs) when this runbook is being used to
  qualify a code change, not just to re-confirm an already-verified state.
- File-size/variant-count comparisons (1e/2e) are suggestive, not conclusive — section 1c/1f
  and 2c/2f exist specifically because a wrong-but-still-restrictive interval file, or a flag
  that silently failed to apply, can still produce a smaller BAM and fewer variants.
