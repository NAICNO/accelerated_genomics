# NF Smoke test - config merge

## Nextflow config merge validation `nf_config_merge_smoketest.nf`

This smoke test verifies that the split Nextflow configuration model merges correctly when cluster identity profiles and resource-sizing profiles are combined with `-profile`.

It is intended to validate the shared config structure used by the AUS workflows, specifically:

- Cluster identity profiles:
  - `AUS/configs/PARABRICKS_TSD.conf`
  - `AUS/configs/PARABRICKS_FOX.conf`
- Resource-sizing profiles:
  - `AUS/configs/resources_test.conf`
  - `AUS/configs/resources_production.conf`

Unlike the other smoke tests, this one is not about real bioinformatics work or container execution. It is a configuration-behavior test that confirms Nextflow merges `withLabel`, `withName`, and base `process {}` settings the way the pipelines assume.

## What this test validates

- A cluster profile such as `tsd` or `fox` can be combined with a resource profile such as `test` or `production`.
- `withLabel: gpu_process` settings from the cluster config merge correctly with `withName: FQ2BAM` settings from the resource config.
- Plain cluster-level `process {}` defaults merge correctly with `withName: PREPON` resource settings.
- TSD-specific `clusterOptions` logic can derive `--mem-per-cpu` from `task.memory` and `task.cpus` supplied by the resource profile.
- The workflow fails fast if no resource-sizing profile is selected.
- Profile order does not change the generated task submission script.

## Files

- `nf_config_merge_smoketest.nf`: dummy workflow with two `echo`-only processes:
  - `FQ2BAM`
  - `PREPON`
- `nf_config_merge_smoketest.config`: test-specific config that exposes the `tsd`, `fox`, `test`, and `production` profiles by including the real shared config files.
- `nf-config-merge-smoke-test.md`: detailed draft checklist and rationale for the test.

## Test design

This workflow uses two stub processes named after real workflow processes:

- `FQ2BAM`
  - carries `label 'gpu_process'`
  - exercises cluster GPU settings plus resource-profile process sizing
- `PREPON`
  - has no GPU label
  - exercises cluster defaults plus resource-profile process sizing

The processes only print small status messages. The real validation is done by inspecting the generated Nextflow task launcher file in each work directory:

```bash
cat work/<hash>/.command.run
```

## Prerequisites

1. Access to either TSD or Fox with SLURM permissions.
2. For TSD, replace the placeholder project/account value in `AUS/configs/PARABRICKS_TSD.conf` if that has not already been done.
3. For Fox, confirm the account value in `AUS/configs/PARABRICKS_FOX.conf` matches your project.
4. Run the test from this directory so the local config and trace file paths behave as documented.

## Run options

### Test 01: TSD + test sizing

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile tsd,test
```

### Test 02: TSD + production sizing

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile tsd,production
```

### Test 03: Fox + test sizing

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile fox,test
```

### Test 04: Fox + production sizing

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile fox,production
```

### Test 05: profile-order check

Re-run one combination with the profile order reversed and confirm the generated task scripts are unchanged.

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile test,tsd
```

### Test 06: fail-fast check

Omit both resource-sizing profiles and confirm the workflow stops immediately before submitting the real tasks.

```bash
nextflow run nf_config_merge_smoketest.nf -c nf_config_merge_smoketest.config \
  -profile tsd
```

## Expected result

A successful run completes both dummy processes without task failures:

- `FQ2BAM`
- `PREPON`

You should also see:

- a Nextflow trace file:
  - `trace_nf_config_merge_smoketest.txt`
- two task work directories containing `.command.run`

For validation, inspect each task's `.command.run` file and confirm the profile merge behavior.

### `FQ2BAM` checks

- GPU request is present:
  - TSD: `--gres=gpu:1`
  - Fox: `--gpus=1`
- The accelerator partition is present.
- CPU and time settings match the selected resource profile:
  - `test`: `cpus 16`, `time 20m`
  - `production`: `cpus 16`, `time 6h`
- On TSD, `--mem-per-cpu` is present and reflects `memory / cpus` from the selected resource profile.
- The correct account is present.

### `PREPON` checks

- No GPU request is present.
- CPU and time settings match the selected resource profile:
  - `test`: `cpus 4`, `time 20m`
  - `production`: `cpus 4`, `time 2h`
- On TSD, `--mem-per-cpu` is present and reflects `memory / cpus` for `PREPON`.
- The correct account is present.
- The accelerator partition is not requested.

### Fail-fast check

When run without `test` or `production`, the workflow should exit quickly with the message:

```text
No resource-sizing profile selected. Add `production` or `test` to -profile alongside `tsd`/`fox`, e.g. -profile tsd,test
```

No real `FQ2BAM` or `PREPON` jobs should be submitted.

## Troubleshooting scope

If this test fails, the likely issue is in the shared Nextflow config structure rather than pipeline business logic. Typical causes include:

- missing or incorrect account/project configuration
- unexpected selector precedence or merge behavior
- cluster-specific SLURM option differences
- incorrect assumptions about how `task.memory` and `task.cpus` propagate into `clusterOptions`

If the workflow runs but the `.command.run` contents do not match expectations, the split config model should not be trusted until the mismatch is explained.
