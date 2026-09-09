# nf_exome_interval_smoketest checklist

Regression check for the `--interval-file` / `--use-wes-model` / `--model-type`
conditional-argument logic added per `EXOME_PROCESSING_SPECS_DEV.md`. Runs
entirely locally (no container, no cluster) -- it re-implements the exact
conditional-string lines from the real modules in stub processes so any drift
between this test and the shipped modules is caught by diffing the two.

## How to run

From this directory:

```
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wgs
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wes --interval_file /any/path/targets.bed
```

(`interval_file` doesn't need to exist for this test -- the stubs only check
the resolved *string*, they never read the file's contents.)

## Checklist

- [ ] `wgs` run (default, no `--interval_file`): none of the seven echoed lines
      contain `--interval-file` or `--use-wes-model`.
- [ ] `wgs` run: `DEEPSOMATIC_STUB`'s line contains `--model-type WGS`.
- [ ] `wes` run: `FQ2BAM_STUB`'s line contains **no** `--interval-file` (section
      4a -- fq2bam is the one module that must never get it).
- [ ] `wes` run: `BQSR_STUB`, `APPLYBQSR_STUB`, `HAPLOTYPECALLER_STUB`,
      `MUTECTCALLER_STUB` each contain `--interval-file <path>`.
- [ ] `wes` run: `DEEPVARIANT_STUB` contains both `--use-wes-model` and
      `--interval-file <path>`.
- [ ] `wes` run: `DEEPSOMATIC_STUB` contains `--model-type WES` and
      `--interval-file <path>`.
- [ ] Re-run with `--sequencing_type wes` and no `--interval_file`: workflow
      errors before any process runs (fail-fast check, section 7).
- [ ] Re-run with `--sequencing_type wgs --interval_file /any/path.bed`:
      workflow errors before any process runs (fail-fast check, section 7).
- [ ] Re-run with an invalid `--sequencing_type foo`: workflow errors before
      any process runs.

## Known gap

This test checks the conditional-argument *logic* against a copy of it, not
the real modules directly -- it does not catch a case where a module in
`modules/*.nf` is edited later without updating both the module and this
test's stub in lockstep. If that drift risk becomes a real problem, consider
having the real modules `include`-able in isolation (they currently aren't
designed for that) or extracting the conditional-arg logic into a shared
Groovy function both the modules and this test call.

## Status

Not yet run against a live Nextflow install (unavailable in the environment
this was written in). Written but unexecuted -- run it and check off the
boxes above before considering this closed, same convention as other
`tests/nf_*_smoketest` directories in this repo.
