# nf_config_merge_smoketest: verifying the profile-split config merge

Verifies that `configs/PARABRICKS_TSD.conf` / `configs/PARABRICKS_FOX.conf` (cluster
identity) and `configs/resources_production.conf` /
`configs/resources_test.conf` (per-process sizing) actually merge the way
the split assumes, once combined via `-profile`, and that omitting the
resource profile really fails the run (open decision 3).

None of the other smoke tests answer this: `gpu_diag_smoketest` and
`gpu_fq2bam_smoketest` are standalone `sbatch` scripts that never touch
Nextflow's config parser, and `hello_world.nf` defines its profiles inline
in one file with no `withLabel`/`withName` split across included configs.

## What this test does

Two dummy, `echo`-only processes named after real pipeline processes:

- `FQ2BAM` -- carries `label 'gpu_process'`. Requests a real (tiny) GPU
  allocation, same as the real pipelines' `FQ2BAM` process would.
- `PREPON` -- no label, CPU-only, small footprint.

Neither does any real work; the point is what Nextflow puts in each task's
`.command.run`, not what they print.

## Running it

From this directory, after replacing `pXX` in
`configs/PARABRICKS_TSD.conf` and confirming `params.account` in
`configs/PARABRICKS_FOX.conf` matches your project (same one-time setup as
the real pipelines):

```bash
sbatch run_nf_config_merge_smoketest_tsd.sbatch          # tsd,test (default)
sbatch run_nf_config_merge_smoketest_tsd.sbatch tsd,production
sbatch run_nf_config_merge_smoketest_fox.sbatch          # fox,test (default)
sbatch run_nf_config_merge_smoketest_fox.sbatch fox,production
```

Run at least the `test` combo on both clusters before trusting the split;
`production` combos are optional (same merge mechanism, just different
numbers -- lower priority to verify since they're closer to what the
existing per-cluster files already had).

## Checklist: after a run completes

For each task, find its work directory (`squeue`/`sacct` while running, or
`trace_nf_config_merge_smoketest.txt` afterward gives the hash), then:

```bash
cat work/<hash>/.command.run
```

**For `FQ2BAM` (tests `withLabel:gpu_process` + `withName:FQ2BAM` merging
from two different included files):**

- [ ] A GPU request directive is present: `--gres=gpu:1` (TSD) or
      `--gpus=1` (Fox) -- from `PARABRICKS_TSD.conf`/`PARABRICKS_FOX.conf`'s
      `withLabel:gpu_process` block.
- [ ] `--partition=accel` (TSD) / the accel partition (Fox) is set --
      same source.
- [ ] cpus/time reflect the resource profile actually selected: 16 cpus,
      20m for `test`, 16 cpus, 6h for `production` -- from
      `resources_production.conf`/`resources_test.conf`'s
      `withName:FQ2BAM` block, NOT from the cluster file (which no longer
      sets these at all).
- [ ] **TSD only:** `--mem-per-cpu=` is present and its value equals
      `memory / cpus` for whichever profile was selected (e.g. test
      profile: 64GB / 16 cpus = 4000M) -- confirms the `clusterOptions`
      closure correctly picked up `task.memory`/`task.cpus` from the
      *separately included* resource file, not a hardcoded value.
- [ ] `--account=` is present and correct.

**For `PREPON` (tests the cluster file's plain `process{}` defaults +
`withName:PREPON` merging):**

- [ ] No GPU request directive present (this process has no
      `gpu_process` label).
- [ ] cpus/time reflect the resource profile: 4 cpus, 20m for `test`, 4
      cpus, 2h for `production`.
- [ ] **TSD only:** `--mem-per-cpu=` present, equal to `memory / cpus` for
      this process specifically (e.g. test profile: 16GB / 4 cpus =
      4000M) -- same value as `FQ2BAM`'s here since both test-profile
      entries happen to use a 4000M/cpu ratio, but confirm it's actually
      being computed per-process, not copy-pasted (deliberately vary one
      test-profile value and re-run if you want to be sure it's not
      coincidental).
- [ ] `--account=` present and correct; no `--partition=accel`.

**Profile order:** re-run once with `test,tsd` (or `production,fox`) --
the reversed order -- and confirm both tasks' `.command.run` are
byte-for-byte identical to the corresponding forward-order run. If not,
selector merge order matters more than assumed and
`docs/profile_specification.md` needs another look before trusting any
single command in the README/config header examples.

**Fail-fast check (open decision 3):**

```bash
sbatch run_nf_config_merge_smoketest_tsd.sbatch tsd    # no test/production
```

- [ ] The run errors out immediately with the
      `No resource-sizing profile selected...` message, before submitting
      any SLURM jobs for `FQ2BAM`/`PREPON` (check `squeue` shows nothing
      new besides the driver job itself, which should exit non-zero
      quickly).

## Recording results

Once run, note the outcome (pass/fail per checklist item, per cluster) in
project memory or back in `docs/profile_specification.md`'s open decision
4 -- this test existing doesn't itself close that decision, an actual
passing run on both clusters does.
