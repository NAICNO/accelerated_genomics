# nf_giraffe_arg_smoketest checklist

Tier 0 of `docs/Giraffe_implementation_specs_dev.md` (section 10). Local check: no
container, no GPU, no cluster. Written **before** `modules/giraffe.nf` exists, per the
spec's TDD rule (section 3). Same stub pattern as `tests/nf_exome_interval_smoketest/`.

Two parts:

| File | What it checks | State today |
|---|---|---|
| `nf_giraffe_arg_smoketest.nf` (+ `.config`) | The **planned logic**: fail-fast checks, the aligner branch, the resolved `pbrun giraffe` command, `publishDir` nesting. The stubs are the spec for the real code. | 🟢 all cases pass (2026-09-23) |
| `check_module_sync.sh` | The **real files** (`modules/giraffe.nf`, `modules/fq2bam.nf`, `modules/applybqsr.nf`, `germline_workflow.nf`, `germline.config`) contain the same flags/patterns as the stubs. | 🔴 Red — expected until spec sections 11–13 and 5h are implemented |

The stubs include the corrections Tier 1 found (see `docs/Giraffe_tier2_context.md`
section 2): `--sample`/`--read-group`, not `--read-group-sm`; `--tmp-dir`;
`--out-duplicate-metrics`; `.bai` emitted without an indexing step; `publishDir` elvis
fallback written inline in the closure (no `def` among the directives); no `publishDir`
on BQSR.

## How to run

From this directory. Graph/FASTQ paths do not need to exist; only resolved names are
checked.

```bash
G="--graph_gbz /x/g.gbz --graph_dist /x/g.dist --graph_min /x/g.min --graph_zipcodes /x/g.zipcodes --graph_ref_paths /x/g.primary.paths"
C="-c nf_giraffe_arg_smoketest.config"      # germline.config's planned defaults

nextflow run nf_giraffe_arg_smoketest.nf $C                                   # 1 default -> fq2bam
nextflow run nf_giraffe_arg_smoketest.nf $C --germline_mapping giraffe $G     # 2 giraffe
nextflow run nf_giraffe_arg_smoketest.nf $C --germline_mapping giraffe $G \
    --sequencing_type wes --interval_file /x/targets.bed                      # 3 giraffe + WES
nextflow run nf_giraffe_arg_smoketest.nf --entrypoint somatic                 # 4 somatic (NO -c)
nextflow run nf_giraffe_arg_smoketest.nf $C --germline_mapping giraffe \
    --graph_gbz /x/g.gbz --graph_dist /x/g.dist --graph_min /x/g.min --graph_ref_paths /x/p   # 5 missing zipcodes
nextflow run nf_giraffe_arg_smoketest.nf $C --graph_gbz /x/g.gbz --graph_min /x/m          # 6 graph_* under fq2bam
nextflow run nf_giraffe_arg_smoketest.nf $C --germline_mapping bwa            # 7 bad enum
nextflow run nf_giraffe_arg_smoketest.nf                                      # 8 germline, no config

bash check_module_sync.sh                                                     # drift check
```

Clean `results/` between runs 1–4 so the published tree only shows that run's output.
Use `bash check_module_sync.sh`; the exec bit may not survive on every mount.

## Checklist

Runs 1–8 verified 2026-09-23 with Nextflow 25.04.6 (TSD's version), outside the
cluster. Not yet re-run on Fox/TSD login nodes.

- [x] **1 — default is fq2bam.** Only `FQ2BAM_STUB` runs; BQSR/APPLYBQSR get its BAM
      (`aligner=fq2bam`). Published to `bam/fq2bam/SAMPLE01/` and
      `bam_recal/fq2bam/SAMPLE01/`.
- [x] **2 — giraffe branch.** Only `GIRAFFE_STUB` runs; its BAM reaches both
      BQSR and APPLYBQSR through the one shared `ch_aligned_bam` (`aligner=giraffe`).
      Published to `bam/giraffe/…` and `bam_recal/giraffe/…`. Command line has all five
      graph flags, `--in-fq <fq1> <fq2>`, `--sample`/`--read-group`, and matches Tier 1's
      `@PG CL:` flag-for-flag.
- [x] **2 — negatives.** The GIRAFFE line has no `--ref`, no `--read-group-sm`, no
      `--in-se-fq`.
- [x] **3 — WES.** GIRAFFE line has **no** `--interval-file`, even though
      `interval_file` is staged into the task (spec 5c).
- [x] **4 — somatic entrypoint** (`germline_mapping` unset, as in `somatic.config`):
      shared FQ2BAM/APPLYBQSR publish to `bam/fq2bam/…` and `bam_recal/fq2bam/…`, not
      `bam/null/…`. The closure form parses under 25.04.6. Note this is the somatic
      output-path change spec 5h flags for team sign-off.
- [x] **5 — missing graph param** under giraffe: errors, names the missing param, exit 1,
      no task scheduled.
- [x] **6 — graph params under fq2bam:** errors, plural wording correct, exit 1.
- [x] **7 — bad enum:** errors, exit 1.
- [x] **8 — germline without the config:** `Missing required params: germline_mapping`,
      exit 1 (the default must live in `germline.config`).
- [x] **`check_module_sync.sh` is Red today** (exit 1): `modules/giraffe.nf` missing,
      `germline_workflow.nf`/`germline.config`/publishDir changes absent.
- [x] **`check_module_sync.sh` can go Green:** checked against a throwaway mock of the
      planned code (outside the repo): GREEN, exit 0. Putting `--read-group-sm` back into
      the mock turned it Red again (exit 1).
- [ ] **Green against the real code** — after spec sections 11–13 + 5h are written.
- [ ] Re-run 1–8 on a Fox or TSD login node (their Nextflow install).

## Verification runs (2026-09-23)

Run 2 (giraffe):

```
GIRAFFE_STUB pbrun giraffe --in-fq S_R1.fastq.gz S_R2.fastq.gz --gbz-name g.gbz --dist-name g.dist --minimizer-name g.min --zipcodes-name g.zipcodes --ref-paths g.primary.paths --out-bam SAMPLE01.bam --out-duplicate-metrics SAMPLE01.duplicate_metrics.txt --sample SAMPLE01 --read-group SAMPLE01 --num-gpus 1 --tmp-dir ./pbrun_tmp
APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam SAMPLE01.bam --out-bam SAMPLE01.recal.bam
BQSR_STUB pbrun bqsr --ref REF --in-bam SAMPLE01.bam (aligner=giraffe)
results/bam/giraffe/SAMPLE01/SAMPLE01.bam(.bai)
results/bam_recal/giraffe/SAMPLE01/SAMPLE01.recal.bam(.bai)
```

Run 4 (somatic, no `-c`):

```
FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq S_R1.fastq.gz S_R2.fastq.gz --out-bam SAMPLE01.bam
APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam SAMPLE01.bam --out-bam SAMPLE01.recal.bam
results/bam/fq2bam/SAMPLE01/SAMPLE01.bam(.bai)
results/bam_recal/fq2bam/SAMPLE01/SAMPLE01.recal.bam(.bai)
```

Runs 5–8 (exit 1 each):

```
germline_mapping = 'giraffe' requires: graph_zipcodes -- see params.germline.yaml.example for the giraffe branch.
graph_gbz, graph_min were given but germline_mapping is 'fq2bam' -- set --germline_mapping giraffe to actually use them, or drop them.
params.germline_mapping must be 'giraffe' or 'fq2bam', got: bwa
Missing required params: germline_mapping
```

Found while writing: the first draft of `APPLYBQSR_STUB` didn't declare its recal BAM
as an output, so nothing reached `bam_recal/`. `publishDir` only publishes declared
outputs. Fixed before the runs above.

## Known gap

Same as the exome test: the stubs copy the logic rather than include the real modules.
`check_module_sync.sh` narrows that gap. It confirms the real files contain the same
flags and patterns, but it greps text and doesn't run the code. Tier 2's `.command.sh`
inspection on a real cluster run closes the rest.
