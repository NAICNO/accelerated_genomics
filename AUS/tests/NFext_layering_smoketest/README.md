# NF Smoke test - `ext` selector layering semantics

## Nextflow `ext` layering validation `nf_ext_layering_smoketest.nf`

This smoke test verifies how Nextflow resolves `ext` assignments when a process matches both a label-based selector and a more specific name-based selector.

It is intended to validate the specific Nextflow behavior exercised by:

- `withLabel:has_default { ext = [ mem_gb: 8, threads: 2 ] }`
- `withName:LAYERED { ext = [ mem_gb: 64 ] }`

Unlike the config-merge smoke test, this one is not about profile composition, cluster submission, or container execution. It is a focused behavior test that checks whether a more-specific `withName` `ext` map overwrites a label-level `ext` map wholesale or shallow-merges with it.

## What this test validates

- A label-level `ext` default is visible to processes that match only `withLabel`.
- A process that matches both `withLabel` and `withName` resolves `task.ext` deterministically.
- The repo can record whether selector layering uses overwrite semantics or shallow-merge semantics on the Nextflow version under test.
- The observed behavior can be compared across environments if selector resolution is version-sensitive.

## Files

- `nf_ext_layering_smoketest.nf`: dummy workflow with two `echo`-only processes:
  - `LAYERED`
  - `LABEL_ONLY`
- `nf_ext_layering_smoketest.config`: local-executor config that defines a default two-key `ext` map at `withLabel` scope and a one-key override at `withName` scope.
- `nf-ext-layering-smoke-test.md`: checklist and rationale for the test.

## Test design

This workflow uses two stub processes:

- `LABEL_ONLY`
  - carries `label 'has_default'`
  - matches only `withLabel:has_default`
  - acts as the control for label-level defaults
- `LAYERED`
  - carries `label 'has_default'`
  - matches both `withLabel:has_default` and `withName:LAYERED`
  - reveals how Nextflow layers the two `ext` assignments

Each process prints the full resolved `task.ext` map:

```bash
echo "<PROC> RESOLVED task.ext=${task.ext}"
```

The config is designed so the two possible outcomes are easy to distinguish by inspection:

- label-level default: `task.ext == [mem_gb: 8, threads: 2]`
- name-level override: `task.ext == [mem_gb: 64]`

For `LAYERED`, that means either of these outcomes answers the question:

- overwrite semantics: `task.ext == [mem_gb: 64]`
- shallow-merge semantics: `task.ext == [mem_gb: 64, threads: 2]`

## Prerequisites

1. Nextflow `>=24.04.0`.
2. Run the test from this directory so the local config and trace file path behave as documented.
3. Prefer repeating the test on each deployed environment whose selector semantics matter, such as TSD and Fox, because this behavior may be version-sensitive.

## Run options

### Test 01: baseline local run

```bash
nextflow run nf_ext_layering_smoketest.nf -c nf_ext_layering_smoketest.config
```

### Test 02: environment confirmation run

Re-run the same command on any target environment whose Nextflow version you want to validate.

```bash
nextflow run nf_ext_layering_smoketest.nf -c nf_ext_layering_smoketest.config
```

## Expected result

A successful run completes both dummy processes without task failures:

- `LAYERED`
- `LABEL_ONLY`

You should also see:

- workflow log output from each process via `.view`
- a Nextflow trace file:
  - `trace_nf_ext_layering_smoketest.txt`

For validation, inspect the emitted `task.ext` values and record which selector-layering behavior occurred.

### Output checks

- `LABEL_ONLY -> LABEL_ONLY RESOLVED task.ext=[mem_gb:8, threads:2]`
- `LAYERED -> LAYERED RESOLVED task.ext=[mem_gb:64]`
  - this indicates overwrite semantics
- `LAYERED -> LAYERED RESOLVED task.ext=[mem_gb:64, threads:2]`
  - this indicates shallow-merge semantics

## Checklist

- [ ] `LABEL_ONLY` resolves `task.ext == [mem_gb: 8, threads: 2]` -- sanity
      check that the label-level default applies on its own.
- [ ] `LAYERED` resolves EITHER:
  - `task.ext == [mem_gb: 64]` (no `threads` key / `task.ext.threads` is
    `null`) -- **overwrite semantics**, or
  - `task.ext == [mem_gb: 64, threads: 2]` -- **shallow-merge semantics**.
- [ ] Record which outcome actually occurred, explicitly
  - Whichever it is, it becomes a hard rule for this repo:
  - Overwrite means any config relying on a `withLabel` default must restate every key at the `withName` level too;
  - Shallow-merge means it's safe to set only the overridden key at `withName` level and trust the rest to fall through from the label default.
- [ ] Repeat on TSD's and Fox's actual deployed Nextflow versions if
      different from whatever ran the first pass, and confirm the same
      semantics hold on both.

### Interpretation

This is primarily a semantics-discovery test, not a strict pass/fail check on `LAYERED`.

The run is useful if:

- `LABEL_ONLY` confirms the label default is applied
- `LAYERED` clearly resolves to one of the two expected semantic outcomes
- the observed outcome is recorded for the Nextflow version tested

### Failure indicators

Any of the following means the selector behavior should not be trusted until explained:

- `LABEL_ONLY` does not resolve to `[mem_gb:8, threads:2]`
- `LAYERED` resolves to a shape other than `[mem_gb:64]` or `[mem_gb:64, threads:2]`
- keys appear with unexpected values unrelated to either configured map
- output differs unexpectedly between environments that should behave the same

## Recording results

Once run, record the actual outcome explicitly:

- overwrite semantics if `LAYERED` resolves to `[mem_gb:64]`
- shallow-merge semantics if `LAYERED` resolves to `[mem_gb:64, threads:2]`

That result should then be propagated back to the related design notes referenced by the checklist draft in this directory.

## Troubleshooting scope

If this test fails, the likely issue is in Nextflow selector layering or `task.ext` merge behavior rather than pipeline business logic.

Typical causes include:

- version-specific selector resolution behavior
- unexpected handling of map-literal overwrite versus shallow merge
- regression relative to previously investigated `ext` selector behavior
- environment drift between local, Fox, and TSD Nextflow installations

If the workflow output does not match one of the documented outcomes, selector-layering assumptions should not be relied on in production pipeline config until the mismatch is explained.