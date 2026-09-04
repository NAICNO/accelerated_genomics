# nf_ext_multikey_smoketest: multi-key `ext` map-literal resolution

## Objective

- Does a map-literal `ext` assignment with MULTIPLE keys in one selector block
(`ext = [ mem_gb: N, threads: M ]`) resolve all keys correctly
per-process, or does a second key reintroduce cross-selector leakage that
the single-key case happened not to expose?

## Test design

Three processes (`X`, `Y`, `Z`), each with a two-key `ext` map, values chosen so every value is unique across processes and within each process's own map -- any cross-leak or internal key mix-up is immediately
visible.

## Running it

From this directory:

```bash
nextflow run nf_ext_multikey_smoketest.nf -c nf_ext_multikey_smoketest.config
```

Local executor. Run at least once on TSD's deployed Nextflow version --
the one version known to mis-handle the single-key dotted-path case --
since confirming the multi-key map-literal case is clean there matters
more than a laptop/Fox run.

## Checklist

- [ ] `X` -> `mem_gb=64 threads=8`
- [ ] `Y` -> `mem_gb=16 threads=4`
- [ ] `Z` -> `mem_gb=8 threads=32`
- [ ] No process shows another process's `mem_gb` or `threads` value, and
      no process shows its own two values swapped.
- [ ] Confirmed on TSD's deployed Nextflow version specifically.
