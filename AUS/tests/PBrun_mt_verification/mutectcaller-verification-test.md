# mutectcaller_verification_test

Re-runnable check of the somatic Mutect2 branch, to run after **any change to
Mutect2 parameters or wiring**:

```
MUTECTCALLER -> [PB_POSTPON] -> POSTPON (FilterMutectCalls) -> vcf/mutect2/*.filtered.vcf.gz
             -> LEARNORIENTATION --^
```

It reads a **finished** run — no pipeline re-run, no Nextflow, no hard-coded work
hashes. Task work dirs come from `<outdir>/pipeline_info/trace.txt`, which the
pipeline overwrites on every run, so it always checks the latest run in that
outdir (cached tasks included).

## Run

```none
bash AUS/tests/PBrun_mt_verification/mutectcaller-verification-test.md <somatic_resutls_dir>

STRICT=1 bash <PATH>/mutectcaller_verification_test.sh <somatic_resutls_dir>      # treat WARN as failure
BCFTOOLS_SIF= <PATH>/bcftools-1.23--h3a4d415_0.sif bash ...  # bcftools on PATH
EXP_RAW_PON=3310 bash ...                                         # override one baseline
TOL_PCT=5 bash ...                                                # widen tolerance (default 2%)
```

Exit code 0 = no FAIL (and no WARN when `STRICT=1`).

## What it checks

| Section | Check | Kind |
|---|---|---|
| 0 | status of MUTECTCALLER, PREPON, PB_POSTPON, LEARNORIENTATION, POSTPON, VCFQC | info |
| 1 | raw Mutect2 VCF, published filtered VCF + `.tbi` | FAIL |
| C1 | `--mutect-germline-resource` in MUTECTCALLER `.command.sh`; POPAF has >1 distinct value — **SKIP** if the resource has no `INFO/AF` (wiring-only stand-in such as `known_indels.vcf.gz`; C1 is then wired, not verified) | FAIL / SKIP |
| C2 (with `--pon`) | `--pon` passed; raw count vs baseline; PB_POSTPON removes nothing; `INFO/PON=1` count; `FILTER~panel_of_normals` count > 0 and vs baseline | counts WARN, wiring FAIL |
| C2 (no `--pon`) | raw count vs no-PON baseline; PB_POSTPON absent; 0 `panel_of_normals` | WARN / FAIL |
| C3 | `--mutect-f1r2-tar-gz` passed; LEARNORIENTATION model exists **and** POSTPON has `--ob-priors` (or neither, with `--mutect_orientation_filter false`); `FILTER~orientation` count recorded | FAIL / info |
| other | POSTPON passes `--stats`; final PASS count recorded | FAIL / info |

PON vs no-PON and orientation on/off are detected from the run itself, so the same
command works for every combination.

## Baselines (smoke-test TUMOR01/NORMAL01 + synthetic PON)

| Variable | Default | Source |
|---|---|---|
| `EXP_RAW_NOPON` | 4893 | gate N0, raw Mutect2 without PON |
| `EXP_RAW_PON` | 3293 | gate N1, `mutectcaller --pon` |
| `EXP_PON_FLAGGED` | 2940 | gate N2, `pbrun postpon` `INFO/PON=1` |
| `EXP_PON_FILTERED` | 2940 | expected ≈ flagged; first pipeline run 2026-10-08 |

Synthetic PON: `<PATH>/pon_synth.vcf.gz` (E.g., Fox: `/projects/ec232/ngs/reference/parabricks_ref/pon/pon_synth.vcf.gz`)

Counts outside the tolerance are **WARN**, not FAIL: a deliberate parameter change
(e.g. LOD thresholds) can legitimately move them. Read the numbers; if
the new values are the intended result, update the defaults at the top of the
script in the same commit as the parameter change, and say why in the commit message.
These baselines only apply to the smoke-test data — for other data use the history
file to compare runs rather than the baselines.

## History

Each run appends one row to `mutectcaller_verification_history.tsv` (next to the
script): date, git revision, outdir, PON/orientation on/off, raw / flagged /
germline-resource AF yes/no, POPAF distinct values, panel_of_normals / orientation / PASS counts, FAIL / WARN / SKIP totals. Diff rows
before and after a parameter change to see exactly what moved.

## Limits

- Needs the run's `work/` dirs (raw and PB_POSTPON VCFs are not published). Run it
  before cleaning `work/`.
- Checks wiring and counts, not CPU-vs-GPU concordance.
