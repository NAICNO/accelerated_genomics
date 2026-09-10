# NF Smoke test - exome interval argument handling

## Nextflow exome interval validation `nf_exome_interval_smoketest.nf`

This smoke test verifies the conditional argument logic used to switch between whole-genome sequencing (WGS) and whole-exome sequencing (WES) behavior in the AUS Parabricks modules.

It is a logic-level regression test, not a bioinformatics execution test. The workflow runs only stub processes that echo resolved command lines, so it can be executed locally without containers, GPUs, BAM inputs, BED contents, or cluster access.

The purpose is to catch drift in the handling of these arguments:

- `--interval-file`
- `--use-wes-model`
- `--model-type`

The stubs mirror the conditional string construction used in the real modules under `AUS/modules`.

## What this test validates

- `sequencing_type` accepts only `wgs` or `wes`.
- `sequencing_type wes` requires `--interval_file` before any process runs.
- The WGS path does not inject exome-only arguments into the echoed commands.
- `FQ2BAM` remains the one process that never receives `--interval-file`, even in WES mode.
- `BQSR`, `APPLYBQSR`, `HAPLOTYPECALLER`, and `MUTECTCALLER` receive `--interval-file` only when WES mode is selected.
- `DEEPVARIANT` receives both `--interval-file` and `--use-wes-model` when WES mode is selected with `deepvariant_mode=shortread`.
- `DEEPSOMATIC` switches `--model-type` from `WGS` to `WES` based on `sequencing_type` and also receives `--interval-file` in WES mode.

## Files

- `nf_exome_interval_smoketest.nf`: stub Nextflow workflow that reproduces the argument-resolution logic and prints the resulting command lines.
- `README.md`: Test guide for running and validating this smoke test (this file).

The workflow shadows logic from these real modules:

- `AUS/modules/bqsr.nf`
- `AUS/modules/applybqsr.nf`
- `AUS/modules/germline_haplotypecaller.nf`
- `AUS/modules/germline_deepvariant.nf`
- `AUS/modules/somatic_mutectcaller.nf`
- `AUS/modules/somatic_deepsomatic.nf`

## Test design

The workflow defines seven stub processes:

- `FQ2BAM_STUB`
- `BQSR_STUB`
- `APPLYBQSR_STUB`
- `HAPLOTYPECALLER_STUB`
- `DEEPVARIANT_STUB`
- `MUTECTCALLER_STUB`
- `DEEPSOMATIC_STUB`

Each stub prints the command line that would be formed after applying the same conditional argument construction used in the real module. The test therefore validates command assembly rather than data processing.

The workflow uses a placeholder file path, `NO_FILE_INTERVAL`, to represent the WGS case where no interval file should be passed downstream. Every stub except `FQ2BAM_STUB` converts that placeholder into either an empty string or a real `--interval-file <path>` argument.

`DEEPVARIANT_STUB` also checks the WES-specific `--use-wes-model` toggle. `DEEPSOMATIC_STUB` checks the resolved `--model-type` value, which should be `WGS` for WGS runs and `WES` for WES runs.

This is intentionally a narrow test. It does not include the real modules, run Parabricks, inspect container behavior, or validate biological outputs.

## Prerequisites

1. A working Nextflow installation available on `PATH`.
2. Run the commands from this directory so the documented relative paths remain correct.
3. No cluster, container runtime, GPU, reference data, or input BAM/VCF files are required.
4. For the WES run, `--interval_file` only needs to be a path-like string for argument rendering; this smoke test does not inspect the file contents.

## Run options and run commands

Run from `AUS/tests/NF_smoketest_exome_interval`.

### Baseline WGS run

```bash
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wgs
```

### WES run with interval file

```bash
nextflow run nf_exome_interval_smoketest.nf \
  --sequencing_type wes \
  --interval_file targets.bed # any target-file
```

### Invalid sequencing type fail-fast check

```bash
nextflow run nf_exome_interval_smoketest.nf --sequencing_type foo
```

### Missing interval file in WES mode fail-fast check

```bash
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wes
```

## Expected result

Successful runs print seven echoed lines, one per stub process, with no real compute work performed.

For the WGS run:

- none of the echoed lines should contain `--interval-file`
- none of the echoed lines should contain `--use-wes-model`
- `DEEPSOMATIC_STUB` should contain `--model-type WGS`

For the WES run:

- `FQ2BAM_STUB` should still contain no `--interval-file`
- `BQSR_STUB`, `APPLYBQSR_STUB`, `HAPLOTYPECALLER_STUB`, and `MUTECTCALLER_STUB` should each contain `--interval-file /any/path/targets.bed`
- `DEEPVARIANT_STUB` should contain both `--use-wes-model` and `--interval-file /any/path/targets.bed`
- `DEEPSOMATIC_STUB` should contain `--model-type WES` and `--interval-file /any/path/targets.bed`

For the fail-fast runs:

- invalid `sequencing_type` should stop immediately with an input-validation error
- `sequencing_type wes` without `--interval_file` should stop immediately with an input-validation error

### Output checks

Inspect the console output from each run and verify the following:

- exactly seven stub lines are printed in the successful WGS and WES runs
- no successful run launches real Parabricks work or requires data files
- `FQ2BAM_STUB` never contains `--interval-file`
- `DEEPVARIANT_STUB` only contains `--use-wes-model` in the WES run
- `DEEPSOMATIC_STUB` flips between `--model-type WGS` and `--model-type WES` as expected
- fail-fast runs terminate before stub command output begins

## Complete Checklist

- [ ] WGS run completes and prints all seven stub lines.
- [ ] WGS run prints no `--interval-file` anywhere.
- [ ] WGS run prints no `--use-wes-model` anywhere.
- [ ] WGS run prints `DEEPSOMATIC_STUB` with `--model-type WGS`.
- [ ] WES run completes and prints all seven stub lines.
- [ ] WES run prints no `--interval-file` in `FQ2BAM_STUB`.
- [ ] WES run prints `--interval-file` in `BQSR_STUB`.
- [ ] WES run prints `--interval-file` in `APPLYBQSR_STUB`.
- [ ] WES run prints `--interval-file` in `HAPLOTYPECALLER_STUB`.
- [ ] WES run prints `--interval-file` in `MUTECTCALLER_STUB`.
- [ ] WES run prints both `--use-wes-model` and `--interval-file` in `DEEPVARIANT_STUB`.
- [ ] WES run prints `--model-type WES` and `--interval-file` in `DEEPSOMATIC_STUB`.
- [ ] Invalid `sequencing_type` fails before any process runs.
- [ ] `sequencing_type wes` without `--interval_file` fails before any process runs.
- [ ] `sequencing_type` `wes` with `--interval_file` fails before any process runs.

### Failure indicators

- `FQ2BAM_STUB` includes `--interval-file` in any run.
- Any WGS output includes `--interval-file` or `--use-wes-model`.
- `DEEPVARIANT_STUB` omits `--use-wes-model` in the WES shortread case.
- `DEEPSOMATIC_STUB` reports the wrong `--model-type` for the selected sequencing mode.
- A fail-fast scenario proceeds into stub execution instead of stopping during parameter validation.
- The output pattern in this smoke test no longer matches the real argument-building logic in the corresponding modules.

## Known gaps

- This smoke test duplicates the module logic instead of importing it directly, so synchronized but incorrect edits in both places could still pass.
- The test validates resolved command-line strings only. It does not validate Parabricks runtime behavior, container behavior, file accessibility, or biological outputs.
- The older checklist note in this directory mentions a fail-fast case for `wgs` combined with `--interval_file`, but the current workflow script does not implement that validation.

## Troubleshooting scope

If this test fails, the problem is likely in conditional argument construction or in the contract between top-level workflow parameters and module inputs, not in biological computation.

Likely investigation targets:

- parameter validation near the top of `nf_exome_interval_smoketest.nf`
- interval placeholder handling using `NO_FILE_INTERVAL`
- WES flag assembly in `AUS/modules/germline_deepvariant.nf`
- model-type resolution in `AUS/modules/somatic_deepsomatic.nf`
- drift between the copied stub logic and the real modules it is intended to mirror
