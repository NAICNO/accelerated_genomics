# NF Smoke test - multi-key `ext` map-literal resolution

## Nextflow `ext` selector validation `nf_ext_multikey_smoketest.nf`

This smoke test verifies that a map-literal `ext` assignment with multiple keys in a single `withName` selector resolves correctly per process.

It is intended to validate the specific Nextflow behavior exercised by:

- `withName:X { ext = [ mem_gb: 64, threads: 8 ] }`
- `withName:Y { ext = [ mem_gb: 16, threads: 4 ] }`
- `withName:Z { ext = [ mem_gb: 8, threads: 32 ] }`

Unlike the config-merge smoke test, this one is not about profile composition, cluster submission, or container execution. It is a focused behavior test that checks whether multiple `ext` keys assigned together in one selector block stay correctly scoped to the owning process.

## What this test validates

- A two-key `ext` map-literal resolves correctly for each process.
- `task.ext.mem_gb` and `task.ext.threads` remain bound to the correct process.
- No value leaks across `withName` selectors.
- No internal key mix-up occurs within a single process's own `ext` map.
- The map-literal form behaves correctly on the deployed Nextflow version under test, especially where earlier single-key dotted-path behavior raised scoping concerns.

## Files

- `nf_ext_multikey_smoketest.nf`: dummy workflow with three `echo`-only processes:
  - `X`
  - `Y`
  - `Z`
- `nf_ext_multikey_smoketest.config`: local-executor config that assigns a unique two-key `ext` map to each process via `withName` selectors.
- `nf-ext-multikey-smoke-test.md`: short checklist and rationale for the test.

## Test design

This workflow uses three stub processes named `X`, `Y`, and `Z`.

Each process prints the values it resolves from `task.ext`:

```bash
echo "<PROC> RESOLVED mem_gb=${task.ext.mem_gb} threads=${task.ext.threads}"
```

The configured values are deliberately unique both across processes and within each process's own two-key map:

- `X`: `mem_gb=64`, `threads=8`
- `Y`: `mem_gb=16`, `threads=4`
- `Z`: `mem_gb=8`, `threads=32`

That makes any of the following immediately visible in the workflow output:

- cross-process leakage of `mem_gb`
- cross-process leakage of `threads`
- swapping of `mem_gb` and `threads` inside one process

## Prerequisites

1. Nextflow `>=24.04.0`.
2. Run the test from this directory so the local config and trace file path behave as documented.
3. Prefer running it at least once on the deployed TSD Nextflow version if that is the environment of concern, since this test exists to probe selector-scoping behavior that may be version-sensitive.

## Run options

### Test 01: baseline local run

```bash
nextflow run nf_ext_multikey_smoketest.nf -c nf_ext_multikey_smoketest.config
```

### Test 02: environment confirmation run

Re-run the same command on the target environment whose Nextflow version you want to validate, such as TSD.

```bash
nextflow run nf_ext_multikey_smoketest.nf -c nf_ext_multikey_smoketest.config
```

## Expected result

A successful run completes all three dummy processes without task failures:

- `X`
- `Y`
- `Z`

You should also see:

- workflow log output from each process via `.view`
- a Nextflow trace file:
  - `trace_nf_ext_multikey_smoketest.txt`

For validation, confirm the emitted lines match the configured `ext` values exactly.

### Output checks

- `X -> X RESOLVED mem_gb=64 threads=8`
- `Y -> Y RESOLVED mem_gb=16 threads=4`
- `Z -> Z RESOLVED mem_gb=8 threads=32`

## Checklist

- [ ] `X` -> `mem_gb=64 threads=8`
- [ ] `Y` -> `mem_gb=16 threads=4`
- [ ] `Z` -> `mem_gb=8 threads=32`
- [ ] No process shows another process's `mem_gb` or `threads` value, and no process shows its own two values swapped.
- [ ] Confirmed on FOX's and TSD's deployed Nextflow version specifically (e.g., the `26.08.0-edge` standalone distribution on both TSD and Fox).

### Failure indicators

Any of the following means the selector behavior should not be trusted until explained:

- one process shows another process's `mem_gb` value
- one process shows another process's `threads` value
- one process prints its own values swapped, such as `mem_gb=32 threads=8`
- output differs between environments that are expected to behave the same

## Troubleshooting scope

If this test fails, the likely issue is in Nextflow selector scoping or `task.ext` resolution rather than pipeline business logic.

If the workflow output does not match the configured values exactly, the multi-key map-literal pattern should not be relied on in production pipeline config until the mismatch is explained.