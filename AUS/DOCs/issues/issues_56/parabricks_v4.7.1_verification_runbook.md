# Runbook: Verifying the pipeline against Parabricks v4.7.1

Tests `clara-parabricks_4.7.1-1.sif` against the germline and somatic pipelines, previously validated on v4.3.1.

## Run metadata

| Field | Value |
|---|---|
| New Parabricks version | `4.7.1-1` |
| Previously validated version | `4.3.1` |
| Container path | `/projects/ec232/ngs/ngs_singularity/clara-parabricks_4.7.1-1.sif` |
| Date tested | 2026-08-31 |
| Tested by | Pubudu |

## Goal

1. Confirm that every GPU-accelerated process in both pipelines run to completion unchanged against the new Parabricks container or determine if pipelines code-base require changes
2. Verify that both pipelines actually used new container's binary — not a cached/older one

## Prerequisites

- Latest Parabricks singularity image available: `clara-parabricks_4.7.1-1.sif`
- Working `-profile singularity,fox` (`-profile singularity,tsd`) setup and existing `params.somatic.yaml` / `params.germline.yaml`
- SLURM/GPU allocation for a full test run of both pipelines

### Singularity/Apptainer image from the [NVIDIA NGC registry](https://catalog.ngc.nvidia.com/orgs/nvidia/clara/containers/clara-parabricks/-)

```bash
# Pull and convert the Docker image into a Singularity Image Format (.sif)
apptainer build clara-parabricks_4.7.1-1.sif docker://nvcr.io/nvidia/clara/clara-parabricks:4.7.1-1
```

## Steps

### 1. Point params at the new container

In both `params.somatic.yaml` and `params.germline.yaml`:

```yaml
parabricks_container: file:///projects/ec232/ngs/ngs_singularity/clara-parabricks_4.7.1-1.sif
```

### 2. Run the somatic pipeline

```bash
./nextflow run "${WORK_DIR}/somatic_main.nf" \
-c "${WORK_DIR}/somatic.config" \
-profile singularity,fox \
-params-file params.somatic.yaml
```

**Test run output:**

```
executor >  slurm (11)
[f7/0a6c58] FQ2BAM (NORMAL01)                  [100%] 2 of 2 ✔
[9b/b55905] BQSR (NORMAL01)                    [100%] 2 of 2 ✔
[ce/2daee6] APPLYBQSR (NORMAL01)               [100%] 2 of 2 ✔
[95/e2e2cc] MUTECTCALLER (TUMOR01_vs_NORMAL01) [100%] 1 of 1 ✔
[5b/e2c5ad] PREPON (TUMOR01_vs_NORMAL01)       [100%] 1 of 1 ✔
[0b/8c66d9] POSTPON (TUMOR01_vs_NORMAL01)      [100%] 1 of 1 ✔
[69/166944] VCFQC (TUMOR01_vs_NORMAL01)        [100%] 1 of 1 ✔
[19/d7a023] DEEPSOMATIC (TUMOR01_vs_NORMAL01)  [100%] 1 of 1 ✔
Completed at: 31-Aug-2026 17:24:08
Duration    : 9m 1s
CPU hours   : 1.3
Succeeded   : 11
```

- [x] All somatic tasks succeeded

### 3. Run the germline pipeline

```bash
./nextflow run "${WORK_DIR}/germline_workflow.nf" \
  -c "${WORK_DIR}/germline.config" \
  -profile singularity,fox \
  -params-file params.germline.yaml
```

**Test run output:**

```
executor >  slurm (7)
[70/066a78] FQ2BAM (SAMPLE01)                [100%] 1 of 1 ✔
[d8/d70779] BQSR (SAMPLE01)                  [100%] 1 of 1 ✔
[e2/a4a97c] APPLYBQSR (SAMPLE01)             [100%] 1 of 1 ✔
[d3/c60566] DEEPVARIANT (SAMPLE01)           [100%] 1 of 1 ✔
[ff/308e08] HAPLOTYPECALLER (SAMPLE01)       [100%] 1 of 1 ✔
[f6/addbcf] VCFQC (SAMPLE01_haplotypecaller) [100%] 2 of 2 ✔
Completed at: 31-Aug-2026 18:05:27
Duration    : 19m 51s
CPU hours   : 0.8
Succeeded   : 7
```

- [x] All germline tasks succeeded

### 4. Sanity-check outputs exist

**Results tree (somatic):**

```
results
├── [ 4.0K]  bam
│   ├── [ 4.0K]  NORMAL01
│   │   ├── [ 1.4G]  NORMAL01.bam
│   │   └── [ 1.9M]  NORMAL01.bam.bai
│   └── [ 4.0K]  TUMOR01
│       ├── [ 1.5G]  TUMOR01.bam
│       └── [ 1.9M]  TUMOR01.bam.bai
├── [ 4.0K]  bam_recal
│   ├── [ 4.0K]  NORMAL01
│   │   ├── [ 1.3G]  NORMAL01.recal.bam
│   │   └── [ 1.9M]  NORMAL01.recal.bam.bai
│   └── [ 4.0K]  TUMOR01
│       ├── [ 1.4G]  TUMOR01.recal.bam
│       └── [ 1.9M]  TUMOR01.recal.bam.bai
├── [ 4.0K]  qc
│   └── [ 4.0K]  vcf
│       └── [  19K]  TUMOR01_vs_NORMAL01.vcf_stats.txt
└── [ 4.0K]  vcf
    ├── [ 4.0K]  deepsomatic
    │   └── [ 5.8M]  TUMOR01_vs_NORMAL01.deepsomatic.vcf
    └── [ 4.0K]  mutect2
        ├── [ 618K]  TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz
        └── [ 4.5K]  TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz.tbi
```

**Results tree (germline):**

```
results
├── bam
│   └── SAMPLE01
│       ├── SAMPLE01.bam
│       └── SAMPLE01.bam.bai
├── bam_recal
│   └── SAMPLE01
│       ├── SAMPLE01.recal.bam
│       └── SAMPLE01.recal.bam.bai
├── qc
│   └── vcf
│       ├── deepvariant
│       │   └── SAMPLE01.deepvariant.vcf_stats.txt
│       └── haplotypecaller
│           └── SAMPLE01.haplotypecaller.vcf_stats.txt
└── vcf
    ├── deepvariant
    │   └── SAMPLE01.deepvariant.vcf
    └── haplotypecaller
        └── SAMPLE01.haplotypecaller.vcf
```

- [x] Somatic results tree matches expected layout, non-trivial file sizes (BAMs ~1.3-1.5G, VCFs non-empty)
- [x] Germline results tree matches expected layout, non-trivial file sizes

### 5. Confirm the new Parabricks version was actually used

**BAM files:**

```bash
samtools view -H results_somatic_v4.7/bam_recal/*/*.recal.bam | grep "4.7.1-1"
```

*Output:*

```
@PG	ID:pbrun fq2bam	PN:pbrun fq2bam	VN:4.7.1-1	CL:pbrun fq2bam --ref Homo_sapiens_assembly38.fasta --in-fq sample_normal_1.fastq.gz sample_normal_2.fastq.gz --out-bam NORMAL01.bam --read-group-sm NORMAL01 --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/f7/0a6c580b2767fef6ab83dc4c877613/pbrun_tmp
@PG	ID:pbrun applybqsr	PN:pbrun applybqsr	VN:4.7.1-1	CL:pbrun applybqsr --ref Homo_sapiens_assembly38.fasta --in-bam NORMAL01.bam --in-recal-file NORMAL01.recal.table --out-bam NORMAL01.recal.bam --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/ce/2daee6d51b650b458762df513289f1
```

```bash
samtools view -H results/bam_recal/*/*.recal.bam | grep "4.7.1-1"
```

*Output:*

```
@PG	ID:pbrun fq2bam	PN:pbrun fq2bam	VN:4.7.1-1	CL:pbrun fq2bam --ref Homo_sapiens_assembly38.fasta --in-fq sample_normal_1.fastq.gz sample_normal_2.fastq.gz --out-bam SAMPLE01.bam --read-group-sm SAMPLE01 --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/70/066a782b8a6a4d9128617af602d885/pbrun_tmp
@PG	ID:pbrun applybqsr	PN:pbrun applybqsr	VN:4.7.1-1	CL:pbrun applybqsr --ref Homo_sapiens_assembly38.fasta --in-bam SAMPLE01.bam --in-recal-file SAMPLE01.recal.table --out-bam SAMPLE01.recal.bam --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/e2/a4a97ccae016d9daa8eb3ca758b8e0
```

- [x] Somatic BAMs (NORMAL01 + TUMOR01) confirmed — `fq2bam` and `applybqsr` show `VN:4.7.1-1`
- [x] Germline BAM (SAMPLE01) confirmed — `fq2bam` and `applybqsr` show `VN:4.7.1-1`

**VCF files (somatic):**

```bash
grep "4.7.1-1" results_somatic_v4.7/vcf/deepsomatic/TUMOR01_vs_NORMAL01.deepsomatic.vcf
zgrep "4.7.1-1" results_somatic_v4.7/vcf/mutect2/TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz
```

*Output:*

```
##GATKCommandLine=<ID=deepsomatic,CommandLine="pbrun deepsomatic --ref Homo_sapiens_assembly38.fasta --in-tumor-bam TUMOR01.recal.bam --in-normal-bam NORMAL01.recal.bam --out-variants TUMOR01_vs_NORMAL01.deepsomatic.vcf --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/19/d7a023050deabdab159fc295afe3a5",Version="4.7.1-1",Date="31/08/2026 17:21:22">
```

```
##GATKCommandLine=<ID=mutectcaller,CommandLine="pbrun mutectcaller --ref Homo_sapiens_assembly38.fasta --in-tumor-bam TUMOR01.recal.bam --tumor-name TUMOR01 --normal-name NORMAL01 --in-normal-bam NORMAL01.recal.bam --out-vcf TUMOR01_vs_NORMAL01.mutect2.vcf.gz --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/95/e2e2cc1ac0045732c0a52d29b44c33",Version="4.7.1-1",Date="31/08/2026 17:22:51">
```

**VCF files (germline):**

```bash
grep "4.7.1-1" results/vcf/*/SAMPLE01*vcf
```

*Output:*

```
results/vcf/deepvariant/SAMPLE01.deepvariant.vcf:##GATKCommandLine=<ID=deepvariant,CommandLine="pbrun deepvariant --ref Homo_sapiens_assembly38.fasta --in-bam SAMPLE01.recal.bam --mode shortread --out-variants SAMPLE01.deepvariant.vcf --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/d3/c60566c8c01aea2e94ca72c4ccfc5d",Version="4.7.1-1",Date="31/08/2026 18:03:25">
results/vcf/haplotypecaller/SAMPLE01.haplotypecaller.vcf:##GATKCommandLine=<ID=haplotypecaller,CommandLine="pbrun haplotypecaller --ref Homo_sapiens_assembly38.fasta --in-bam SAMPLE01.recal.bam --out-variants SAMPLE01.haplotypecaller.vcf --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/work/ff/308e08b4a6adbcd167147da17d7dd1",Version="4.7.1-1",Date="31/08/2026 18:04:24">
```

- [x] deepsomatic VCF confirmed — `Version="4.7.1-1"`
- [x] mutect2 VCF confirmed — `Version="4.7.1-1"`
- [x] deepvariant VCF confirmed — `Version="4.7.1-1"`
- [x] haplotypecaller VCF confirmed — `Version="4.7.1-1"`

### 6. Record the result

| Pipeline | Version | Date | Duration | CPU hours | Version grep |
|---|---|---|---|---|---|
| Somatic | 4.7.1-1 | 2026-08-31 | 9m 1s | 1.3 | ✔ all 4 outputs (2 BAM @PG lines, deepsomatic + mutect2 VCFs) |
| Germline | 4.7.1-1 | 2026-08-31 | 19m 51s | 0.8 | ✔ all 4 outputs (2 BAM @PG lines, deepvariant + haplotypecaller VCFs) |

Previous validated version for comparison: v4.3.1 (baseline not re-attached here — see prior test records).

## Sign-off

- [x] All checks above passed — `4.7.1-1` is qualified for adoption
- Signed off by: Pubudu, 2026-08-31

## Notes / gotchas

- `-resume` can make a run "succeed" instantly by reusing old cached results from the previous container version — always do a fresh run (or clear the relevant `work/` dirs) when qualifying a new Parabricks version, and don't rely on "cached" vs "executed" status alone. This run's task IDs (e.g. `f7/0a6c58`, `70/066a78`) are fresh work-dir hashes, consistent with a non-resumed run.
- The version string only proves the *binary* version; it doesn't by itself prove numerical/variant-call equivalence with v4.3.1. A separate VCF diff/concordance check against the v4.3.1 output would be needed to confirm calling behavior is unchanged — not covered by this runbook.
