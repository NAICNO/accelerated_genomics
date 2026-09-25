# Giraffe Tier 2 — Fox runbook

Exact commands for Tier 2 (`docs/Giraffe_implementation_specs_dev.md` section 10,
`docs/Giraffe_tier2_context.md` sections 3–5): the real `germline_workflow.nf` with
`--germline_mapping giraffe` on Fox against the **test reference bundle**, then the
fq2bam baseline into the same outdir.

Files in this folder:

| File | Use |
|---|---|
| `build_primary_ref_fox.sbatch` | Step 2: 24-contig graph-derived `params.ref` (+ `.fai`/`.dict`) |
| `params.giraffe_fox.yaml` / `params.fq2bam_fox.yaml` | Steps 5/7: run parameters (all paths absolute) |
| `run_germline_tier2_fox.sbatch` | Steps 5/7: Nextflow head job; copies a per-aligner trace |
| `verify_tier2.sh` | Steps 6/8: the Tier 2 checklist as commands |

Run times: steps 0–4 and 9 take seconds to minutes on a login node. Step 2 is a Slurm job
(expect < 1 h). Each pipeline run is ~15–30 min on the test data (Tier 1 GIRAFFE ~6 min).

---

## Step 0 — session setup (every new shell)

```bash
export REPO=/path/to/advanced-user-support              # your Fox clone
export NXF=/path/to/nextflow-26.08.0-edge-dist          # the binary used for Tier 0 on Fox
export WORK=/projects/ec232/ngs/analysis/AUS/girrfe_mapper/vg_mapping_exercises
export T2=$REPO/tests/nf_giraffe_tier2_fox

# sbatch scripts that call plain `nextflow` (resource sweep) need it on PATH
mkdir -p ~/bin && ln -sf "$NXF" ~/bin/nextflow && export PATH=$HOME/bin:$PATH

cd $REPO && git log --oneline -1 && nextflow -v
```

## Step 1 — static checks on the pushed code (login node, seconds)

```bash
cd $REPO
bash tests/nf_giraffe_arg_smoketest/check_module_sync.sh | tail -1        # expect GREEN
bash tests/nf_resource_sweep_verification/check_stub_sync.sh              # expect OK ... (11 processes)
nextflow -q -c germline.config config -profile singularity,fox,test -o flat \
  | grep -E "germline_mapping|withName:GIRAFFE"                           # expect fq2bam, 16 cpus, 20m, mem_gb:128
```

Resource sweep (release-verification test; now includes GIRAFFE):

```bash
cd $REPO/tests/nf_resource_sweep_verification
sbatch run_nf_resource_sweep_verification_fox.sbatch fox,test
# when done:
grep -E "process|GIRAFFE|FQ2BAM" resource_sweep_results.tsv && mv resource_sweep_results.tsv fox_test.tsv
sbatch run_nf_resource_sweep_verification_fox.sbatch fox,production
grep -E "process|GIRAFFE|FQ2BAM" resource_sweep_results.tsv && mv resource_sweep_results.tsv fox_production.tsv
```

Expect a `GIRAFFE  16  20m|6h  128  gpu_process` row in each.

## Step 2 — build the 24-contig reference (Slurm, normal partition)

```bash
ls -la $WORK/vg_v1.70.0.sif $WORK/tiny_ref/Homo_sapiens_assembly38.primary.paths   # both must exist
cd $T2 && sbatch build_primary_ref_fox.sbatch
# when done:
grep CHECK giraffe_primary_ref-*.out
```

Expect `CHECK 1 ... OK` and `CHECK 2 ... OK` (byte-identical, or "ignoring case").
Anything else: stop and look before continuing.

## Step 3 — reference matches the Tier 1 BAM header (login node)

```bash
module load SAMtools/1.17-GCC-12.2.0
diff <(samtools view -H $WORK/GIRAFFE_NORMAL01.bam \
        | awk -F'\t' '$1=="@SQ"{sub("SN:","",$2); sub("LN:","",$3); print $2"\t"$3}') \
     <(cut -f1,2 $WORK/tiny_ref/Homo_sapiens_assembly38.primary.gbz.fa.fai) \
  && echo "OK: ref .fai == Tier 1 @SQ"
ls -la $WORK/tiny_ref/Homo_sapiens_assembly38.primary.gbz.{fa,fa.fai,dict}
```

## Step 4 — real-pipeline fail-fast + DAG (login node, `-preview` submits nothing)

```bash
cd $T2
NF="nextflow -q run $REPO/germline_workflow.nf -c $REPO/germline.config -profile singularity,fox,test -preview"

$NF -params-file params.giraffe_fox.yaml -with-dag dag_giraffe.mmd; echo "exit=$?"   # expect exit=0
grep -o '"[A-Z0-9_]*"' dag_giraffe.mmd | sort -u | tr '\n' ' '; echo                 # GIRAFFE, no FQ2BAM
$NF -params-file params.fq2bam_fox.yaml  -with-dag dag_fq2bam.mmd;  echo "exit=$?"   # expect exit=0
grep -o '"[A-Z0-9_]*"' dag_fq2bam.mmd  | sort -u | tr '\n' ' '; echo                 # FQ2BAM, no GIRAFFE

grep -v '^graph_zipcodes:' params.giraffe_fox.yaml > params.nozip.tmp.yaml
$NF -params-file params.nozip.tmp.yaml;                         echo "exit=$?"      # requires: graph_zipcodes, exit=1
$NF -params-file params.fq2bam_fox.yaml --graph_min /x/g.min;   echo "exit=$?"      # graph_min was given ..., exit=1
$NF -params-file params.fq2bam_fox.yaml --germline_mapping bwa; echo "exit=$?"      # must be 'giraffe' or 'fq2bam', exit=1
rm -f dag_*.mmd params.nozip.tmp.yaml
```

## Step 5 — Tier 2 run: giraffe (Slurm head job)

```bash
cd $T2
sbatch run_germline_tier2_fox.sbatch params.giraffe_fox.yaml
squeue -u $USER                      # head job + GIRAFFE/BQSR/... GPU jobs as they are submitted
tail -f nf_giraffe_tier2-*.out       # Ctrl-C when "Trace copied to trace_params.giraffe_fox.txt"
```

If a task fails and you fix something, resume with:
`sbatch run_germline_tier2_fox.sbatch params.giraffe_fox.yaml -resume`

## Step 6 — verify the giraffe run

```bash
cd $T2 && bash verify_tier2.sh giraffe 2>&1 | tee verify_giraffe.txt
```

What to look for (Tier 2 checklist):

| Section | Pass |
|---|---|
| 1 | all 6 tasks `COMPLETED`, `attempt=1`; GIRAFFE `peak_rss` ≈ 75 GB (no OOM retry at 128 GB) |
| 2 | files under `bam/giraffe/`, `bam_recal/giraffe/`, `vcf/giraffe/{deepvariant,haplotypecaller}/`, `qc/vcf/giraffe/*/`, `qc/bam/giraffe/` |
| 3 | `@PG ID:pbrun giraffe ... VN:4.7.1-1`; 24 `@SQ` |
| 4 | `.command.sh` flags match Tier 1's `@PG CL:` flag-for-flag |
| 5 | BQSR messages about known-sites contigs — record them (context doc 3b) |
| 6–7 | both VCFs non-empty; `bcftools stats` numbers present |
| 9 | `OK: identical` |
| 10 | `OK: identical to Tier 1` |

### Contingency — BQSR fails on known-sites contigs

```bash
BC=/projects/ec232/ngs/ngs_singularity/bcftools-1.23--h3a4d415_0.sif
KS=/projects/ec232/ngs/reference/parabricks_ref/Homo_sapiens_assembly38.known_indels.vcf.gz
R=$WORK/tiny_ref/Homo_sapiens_assembly38
singularity exec -B /projects $BC bash -c "
  bcftools view -r $(paste -sd, $R.primary.paths) $KS -Oz -o $R.known_indels.primary.tmp.vcf.gz &&
  bcftools reheader --fai $R.primary.gbz.fa.fai -o $R.known_indels.primary.vcf.gz $R.known_indels.primary.tmp.vcf.gz &&
  bcftools index -t $R.known_indels.primary.vcf.gz && rm $R.known_indels.primary.tmp.vcf.gz"
```

Then, in `params.giraffe_fox.yaml`, swap to the commented-out `known_sites` block and
re-submit with `-resume` (GIRAFFE is cached, only BQSR onward reruns).

## Step 7 — fq2bam baseline, same outdir

```bash
cd $T2
sbatch run_germline_tier2_fox.sbatch params.fq2bam_fox.yaml
tail -f nf_giraffe_tier2-*.out       # newest job's log
```

## Step 8 — verify baseline + compare

```bash
cd $T2
bash verify_tier2.sh fq2bam  2>&1 | tee verify_fq2bam.txt    # regression guard: default path unchanged
bash verify_tier2.sh compare 2>&1 | tee verify_compare.txt   # informational only
find results_tier2 -maxdepth 3 -type d | sort                  # bam/{fq2bam,giraffe}/..., no collisions
```

The comparison measures tool differences only: the test graph has no haplotypes, so it
says nothing about pangenome benefit (see the full-reference task).

## Step 9 — record results

Paste into `tier2-fox-results.md` (this folder): job IDs, `verify_*.txt` output, the step 2
`CHECK` lines, and the BQSR known-sites outcome. Then update the Tier 2 status in
`docs/Giraffe_implementation_specs_dev.md` and `docs/Giraffe_tier2_context.md`.

Clean-up once recorded (work dir holds ~GB of BAM copies):

```bash
cd $T2 && rm -rf work .nextflow* results_tier2
```
