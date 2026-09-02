# Germline & Somatic Pipeline Testing Checklist

**GitHub Issue:** [accelerated_genomics/issues/30](https://github.com/NAICNO/accelerated_genomics/issues/30)
**Date started:** 2026-08-19
**Environment / profile used:** _(`fox`, via `PARABRICKS_FOX.conf`)_
**Pipeline commit/version:** 21985affffea5e2dfbcfc7d6835578bc1c7316d8

---

## 1. Document Sources

- [x] Input data source(s) recorded (path, dataset name, WGS/WES, paired-end vs single)
- [x] Reference genome / index version recorded
- [ ] Any reference truth sets used for validation (e.g. GIAB) recorded - **NA**
- [x] Config file(s) used linked
- [x] Parabricks / CUDA / container version recorded
- [x] Hardware used recorded (node, GPU type/count)

### Sources used

- Test data:
  - Tumor and Normal alignment files: [Parabricks mutect_sample](https://s3.amazonaws.com/parabricks.sample/mutect_sample.tar.gz)
  - Extract reads (FASTQ files) from Tumor and Normal alignment files using `AUS/DOCs/Scripts/pbrun_bam2fq.sbatch`
- Reference data: [Getting the Sample Data from NVIDIA docs](https://docs.nvidia.com/clara/parabricks/tutorials/step-by-step-tutorials/getting-the-sample-data)
- Config file: configs/PARABRICKS_FOX.conf
- Versions/Paths:
  - Parabricks container version - v4.3.1-1
  - Container path: /projects/ec232/ngs/ngs_singularity[clara-parabricks_v4.3.1-1.sig|bcftools-1.23--h3a4d415_0.sif]

**Hardware used:**

`scontrol show job 4064279`

```none
JobId=4064279 JobName=nf-FQ2BAM_(NORMAL01)
   UserId=ec-pubuduss(2101583) GroupId=ec-pubuduss-group(2103998) MCS_label=N/A
   Priority=12585 Nice=0 Account=ec232 QOS=normal
   JobState=RUNNING Reason=None Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:25 TimeLimit=06:00:00 TimeMin=N/A
   SubmitTime=2026-08-19T11:25:19 EligibleTime=2026-08-19T11:25:19
   AccrueTime=2026-08-19T11:25:21
   StartTime=2026-08-19T11:25:22 EndTime=2026-08-19T17:25:22 Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2026-08-19T11:25:22 Scheduler=Main
   Partition=accel AllocNode:Sid=login-4:3232382
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=gpu-11
   BatchHost=gpu-11
   NumNodes=1 NumCPUs=16 NumTasks=1 CPUs/Task=16 ReqB:S:C:T=0:0:*:*
   ReqTRES=cpu=16,mem=64G,node=1,billing=19,gres/gpu=1
   AllocTRES=cpu=16,mem=64G,node=1,billing=19,gres/gpu=1,gres/gpu:rtx30=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=16 MinMemoryNode=64G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) LicensesAlloc=(null) Network=(null)
   Command=.command.run
   WorkDir=/fp/projects01/ec232/ngs/analysis/AUS/work/44/e12d25a206e459a162f44c04b3510c
   StdErr=/fp/projects01/ec232/ngs/analysis/AUS/work/44/e12d25a206e459a162f44c04b3510c/.command.log
   StdIn=/dev/null
   StdOut=/fp/projects01/ec232/ngs/analysis/AUS/work/44/e12d25a206e459a162f44c04b3510c/.command.log
   TresPerJob=gres/gpu:1
   TresPerTask=cpu=16
```

`scontrol show node gpu-11 | grep -i gres`

```none
   Gres=gpu:rtx30:8
   CfgTRES=cpu=96,mem=1974G,billing=252,gres/gpu=8,gres/gpu:rtx30=8
   AllocTRES=cpu=41,mem=176G,gres/gpu=4,gres/gpu:rtx30=4
```

`module list`

```none
Currently Loaded Modules:
  1) Java/25.36
```

---

## 2. Germline Pipeline

### Run (Germline Pipeline)

- [x] Exact run command recorded (copy-pasteable)
- [x] `-profile` used noted
- [x] Run started: _timestamp_
- [x] Run completed: _timestamp_ (wall-clock duration: ___)
- [x] Exit status confirmed (0 / success)
- [x] If `-resume` used: confirmed which tasks actually re-executed vs. were cached (see known resume-cache gotcha — cached ≠ correctly skipped)

**Exact run command:**

```bash
#! /bin/bash

REF_PATH="/projects/ec232/ngs/reference/parabricks_ref"
SAMPLE_PATH="/projects/ec232/ngs/analysis/AUS/test_sample/fastq"
SINGULARITY_CONT="/projects/ec232/ngs/ngs_singularity"
WORK_DIR="/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS"

./nextflow run "${WORK_DIR}/germline_workflow.nf" -c "${WORK_DIR}/germline.config" -profile fox  -resume \
  --sample_id "SAMPLE01" --fastq_1  "${SAMPLE_PATH}/sample_normal_1.fastq.gz" --fastq_2  "${SAMPLE_PATH}/sample_normal_2.fastq.gz" \
  --ref "${REF_PATH}/Homo_sapiens_assembly38.fasta" \
  --known_sites "${REF_PATH}/Homo_sapiens_assembly38.known_indels.vcf.gz" \
  --parabricks_container "${SINGULARITY_CONT}/clara-parabricks_v4.3.1-1.sig" \
  --bcftools_container   "${SINGULARITY_CONT}/bcftools-1.23--h3a4d415_0.sif"
```

**Run command - terminal recording:**

```none
 N E X T F L O W   ~  version 26.04.6

WARN: It appears you have never run this project before -- Option `-resume` is ignored
Launching `/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS/germline_workflow.nf` [crazy_hugle] revision: d916272ab6

executor >  slurm (7)
[02/5a45a7] FQ2…M (SAMPLE01) | 1 of 1 ✔
[df/c50227] BQSR (SAMPLE01)  | 1 of 1 ✔
[54/09306c] APP…R (SAMPLE01) | 1 of 1 ✔
[fa/18a2ad] DEE…T (SAMPLE01) | 1 of 1 ✔
[2c/ebc825] HAP…R (SAMPLE01) | 1 of 1 ✔
[11/590a13] VCF…otypecaller) | 2 of 2 ✔
Completed at: 19-Aug-2026 13:02:52
Duration    : 3m 36s
CPU hours   : 0.7
Succeeded   : 7
```

### Results Examination

- [x] Output directory structure matches expected layout
- [x] HaplotypeCaller output file extensions correct (plain `.vcf` + `.vcf.idx`, **not** `.vcf.gz` — known Parabricks constraint)
- [x] VCF opens/validates (e.g. `bcftools stats` or similar)
- [x] Variant counts look reasonable (not empty, not wildly off)
- [x] Coverage/QC metrics reviewed
- [ ] Compared against truth set, if available - [NA]
- [x] Log files captured/attached as evidence

**Output layout:**

```none
results/
├── [ 4.0K]  bam
│   └── [ 4.0K]  SAMPLE01
│       ├── [ 1.4G]  SAMPLE01.bam
│       └── [ 1.9M]  SAMPLE01.bam.bai
├── [ 4.0K]  bam_recal
│   └── [ 4.0K]  SAMPLE01
│       ├── [ 1.3G]  SAMPLE01.recal.bam
│       └── [ 1.9M]  SAMPLE01.recal.bam.bai
├── [ 4.0K]  qc
│   └── [ 4.0K]  vcf
│       ├── [ 4.0K]  deepvariant
│       │   └── [  19K]  SAMPLE01.deepvariant.vcf_stats.txt
│       └── [ 4.0K]  haplotypecaller
│           └── [ 192K]  SAMPLE01.haplotypecaller.vcf_stats.txt
└── [ 4.0K]  vcf
    ├── [ 4.0K]  deepvariant
    │   └── [ 7.7M]  SAMPLE01.deepvariant.vcf
    └── [ 4.0K]  haplotypecaller
        └── [  17M]  SAMPLE01.haplotypecaller.vcf
```

**HaplotypeCaller output:**

```
## Header rows
$ grep -c "#" results/vcf/haplotypecaller/SAMPLE01.haplotypecaller.vcf
 3392

## Variant rows
$ grep -cv "#" results/vcf/haplotypecaller/SAMPLE01.haplotypecaller.vcf
  83088
```

**Coverage/QC metrics:**

```
## Header section - HaplotypeCaller

  # This file was produced by bcftools stats (1.23+htslib-1.23) and can be plotted using plot-vcfstats.
  # The command line was: bcftools stats  SAMPLE01.haplotypecaller.vcf
  #
  # Definition of sets:
  # ID    [2]id   [3]tab-separated file names
  ID      0       SAMPLE01.haplotypecaller.vcf
  # SN, Summary numbers:
  #   number of records   .. number of data rows in the VCF
  #   number of no-ALTs   .. reference-only sites, ALT is either "." or identical to REF
  #   number of SNPs      .. number of rows with a SNP
  #   number of MNPs      .. number of rows with a MNP, such as CC>TT
  #   number of indels    .. number of rows with an indel
  #   number of others    .. number of rows with other type, for example a symbolic allele or
  #                          a complex substitution, such as ACT>TCGA
  #   number of multiallelic sites     .. number of rows with multiple alternate alleles
  #   number of multiallelic SNP sites .. number of rows with multiple alternate alleles, all SNPs
  #
  #   Note that rows containing multiple types will be counted multiple times, in each
  #   counter. For example, a row with a SNP and an indel increments both the SNP and
  #   the indel counter.
  #
  # SN    [2]id   [3]key  [4]value

## Header section - Deepvariant

  # This file was produced by bcftools stats (1.23+htslib-1.23) and can be plotted using plot-vcfstats.
  # The command line was: bcftools stats  SAMPLE01.deepvariant.vcf
  #
  # Definition of sets:
  # ID    [2]id   [3]tab-separated file names
  ID      0       SAMPLE01.deepvariant.vcf
  # SN, Summary numbers:
  #   number of records   .. number of data rows in the VCF
  #   number of no-ALTs   .. reference-only sites, ALT is either "." or identical to REF
  #   number of SNPs      .. number of rows with a SNP
  #   number of MNPs      .. number of rows with a MNP, such as CC>TT
  #   number of indels    .. number of rows with an indel
  #   number of others    .. number of rows with other type, for example a symbolic allele or
  #                          a complex substitution, such as ACT>TCGA
  #   number of multiallelic sites     .. number of rows with multiple alternate alleles
  #   number of multiallelic SNP sites .. number of rows with multiple alternate alleles, all SNPs
  #
  #   Note that rows containing multiple types will be counted multiple times, in each
  #   counter. For example, a row with a SNP and an indel increments both the SNP and
  #   the indel counter.
  #
  # SN    [2]id   [3]key  [4]value

```

**Log files:**

```bash
$ rsync -avm \
  --include='*/' \
  --include='.command*' \
  --include='.exitcode' \
  --exclude='*' \
  work/ germline_work_logs

tar -zcvf germline_work_logs.tar.gz germline_work_logs
```

---

## 3. Somatic Pipeline

### Run (Somatic Pipeline)

- [x] Exact run command recorded (copy-pasteable)
- [x] `-profile` used noted
- [x] Run started: _timestamp_
- [x] Run completed: _timestamp_ (wall-clock duration: ___)
- [x] Exit status confirmed (0 / success)
- [x] If `-resume` used: confirmed which tasks actually re-executed vs. were cached
- [x] Tumor-only vs tumor-normal mode noted

**Run command:**

```bash
REF_PATH="/projects/ec232/ngs/reference/parabricks_ref"
SAMPLE_PATH="/projects/ec232/ngs/analysis/AUS/test_sample/fastq"
SINGULARITY_CONT="/projects/ec232/ngs/ngs_singularity"
WORK_DIR="/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS"

./nextflow run "${WORK_DIR}/somatic_main.nf" -c "${WORK_DIR}/somatic.config" -profile fox -resume \
  --tumor_id  "TUMOR01"  --tumor_fastq_1  "${SAMPLE_PATH}/sample_tumor_1.fastq.gz"  --tumor_fastq_2  "${SAMPLE_PATH}/sample_tumor_2.fastq.gz" \
  --normal_id "NORMAL01" --normal_fastq_1 "${SAMPLE_PATH}/sample_normal_1.fastq.gz" --normal_fastq_2 "${SAMPLE_PATH}/sample_normal_2.fastq.gz" \
  --ref "${REF_PATH}/Homo_sapiens_assembly38.fasta" \
  --known_sites "${REF_PATH}/Homo_sapiens_assembly38.known_indels.vcf.gz" \
  --germline_resource  "${REF_PATH}/Homo_sapiens_assembly38.known_indels.vcf.gz" \
  --parabricks_container "${SINGULARITY_CONT}/clara-parabricks_v4.3.1-1.sig" \
  --gatk_container       "${SINGULARITY_CONT}/broadinstitute_gatk_4.3.0.0.sif" \
  --bcftools_container   "${SINGULARITY_CONT}/bcftools-1.23--h3a4d415_0.sif"
```

**Run command - terminal record:**

```none
 N E X T F L O W   ~  version 26.04.6

WARN: It appears you have never run this project before -- Option `-resume` is ignored
Launching `/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS/somatic_main.nf` [romantic_hoover] revision: f3b842b765

executor >  slurm (11)
[db/72d60e] FQ2BAM (TUMOR01)                   | 2 of 2 ✔
[9a/262f50] BQSR (TUMOR01)                     | 2 of 2 ✔
[65/4e4ebc] APPLYBQSR (TUMOR01)                | 2 of 2 ✔
[a7/10e047] MUTECTCALLER (TUMOR01_vs_NORMAL01) | 1 of 1 ✔
[df/b60df4] PREPON (TUMOR01_vs_NORMAL01)       | 1 of 1 ✔
[2e/67f8c7] POSTPON (TUMOR01_vs_NORMAL01)      | 1 of 1 ✔
[76/e714d2] VCFQC (TUMOR01_vs_NORMAL01)        | 1 of 1 ✔
[7d/070128] DEEPSOMATIC (TUMOR01_vs_NORMAL01)  | 1 of 1 ✔
Completed at: 19-Aug-2026 11:29:23
Duration    : 4m 6s
CPU hours   : 1.7
Succeeded   : 11
```

### Results Examination (Somatic Pipeline)

- [x] Output directory structure matches expected layout
- [x] MuTect2/MutectCaller output files present and correctly named
- [x] VCF opens/validates
- [x] Variant counts look reasonable
- [x] Coverage/QC metrics reviewed
- [ ] Compared against truth set, if available [NA]
- [x] Log files captured/attached as evidence

**Output layout:**

```none
results/
├── [ 4.0K]  bam
│   ├── [ 4.0K]  NORMAL01
│   │   ├── [ 1.4G]  NORMAL01.bam
│   │   └── [ 1.9M]  NORMAL01.bam.bai
│   └── [ 4.0K]  TUMOR01
│       ├── [ 1.5G]  TUMOR01.bam
│       └── [ 1.9M]  TUMOR01.bam.bai
├── [ 4.0K]  bam_recal
│   ├── [ 4.0K]  NORMAL01
│   │   ├── [ 1.3G]  NORMAL01.recal.bam
│   │   └── [ 1.9M]  NORMAL01.recal.bam.bai
│   └── [ 4.0K]  TUMOR01
│       ├── [ 1.4G]  TUMOR01.recal.bam
│       └── [ 1.9M]  TUMOR01.recal.bam.bai
├── [ 4.0K]  qc
│   └── [ 4.0K]  vcf
│       └── [  19K]  TUMOR01_vs_NORMAL01.vcf_stats.txt
└── [ 4.0K]  vcf
    ├── [ 4.0K]  deepsomatic
    │   └── [ 5.9M]  TUMOR01_vs_NORMAL01.deepsomatic.vcf
    └── [ 4.0K]  mutect2
        ├── [ 621K]  TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz
        └── [ 4.5K]  TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz.tbi
```

**MuTect2/MutectCaller output:**

```none
## Header rows
$ zgrep -c "#" results/vcf/mutect2/TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz
  3437

## Variant records
$ zgrep -cv "#" results/vcf/mutect2/TUMOR01_vs_NORMAL01.mutect2.filtered.vcf.gz
  4913
```

**Deepsomatic output:**

```none
```

**Coverage/QC metrics:**

```none
## Header rows

  # This file was produced by bcftools stats (1.23+htslib-1.23) and can be plotted using plot-vcfstats.
  # The command line was: bcftools stats  TUMOR01_vs_NORMAL01.mutect2.vcf.gz
  #
  # Definition of sets:
  # ID    [2]id   [3]tab-separated file names
  ID      0       TUMOR01_vs_NORMAL01.mutect2.vcf.gz
  # SN, Summary numbers:
  #   number of records   .. number of data rows in the VCF
  #   number of no-ALTs   .. reference-only sites, ALT is either "." or identical to REF
  #   number of SNPs      .. number of rows with a SNP
  #   number of MNPs      .. number of rows with a MNP, such as CC>TT
  #   number of indels    .. number of rows with an indel
  #   number of others    .. number of rows with other type, for example a symbolic allele or
  #                          a complex substitution, such as ACT>TCGA
  #   number of multiallelic sites     .. number of rows with multiple alternate alleles
  #   number of multiallelic SNP sites .. number of rows with multiple alternate alleles, all SNPs
  #
  #   Note that rows containing multiple types will be counted multiple times, in each
  #   counter. For example, a row with a SNP and an indel increments both the SNP and
  #   the indel counter.
  #
  # SN    [2]id   [3]key  [4]value

## Total rows
$ wc -l results/qc/vcf/TUMOR01_vs_NORMAL01.vcf_stats.txt
  617 results/qc/vcf/TUMOR01_vs_NORMAL01.vcf_stats.txt
```

**Log files:**

```bash
rsync -avm \
  --include='*/' \
  --include='.command*' \
  --include='.exitcode' \
  --exclude='*' \
  work/ somatic_work_logs

tar -zcvf somatic_work_logs.tar.gz somatic_work_logs
```

---

## Gaps

### Pipelines

- [x] Testing the pipelines with the basic toolset; need to add comprehensive tools for germline and somatic data processing
- [x] Resource usage logging is not available ([Issue 33](https://github.com/NAICNO/accelerated_genomics/issues/33))
- [x] VCFQC on somatic pipeline was done only on mutectcaller; not on deepsomatic ([Issue 34](https://github.com/NAICNO/accelerated_genomics/issues/34))

### Documentation

- [x] Optional params (e.g., `--deepvariant_mode`) - not tested; need verification
- [x] Requirements - Java for NextFlow execution is not recorded in [closed-issue/31](https://github.com/NAICNO/accelerated_genomics/issues/31); Updated as part of this issue (#30)

---

## 4. Cross-Pipeline Checks

- [ ] Both pipelines tested on same/comparable input data - [NA]
- [ ] Runtime and resource usage compared and recorded - [NA]
- [ ] Any manual workarounds needed during either run documented [NA]
- [x] Known config gotchas re-verified as not reintroduced:
  - [x] No stray characters in config files (e.g. past `§` bug in `PARABRICKS_FOX.conf`)
  - [x] No bare `def` vars in `includeConfig`'d files
  - [x] `publishDir` paths using closures where needed, not plain interpolated GStrings

**Notes:**

- Runtime and resource usage tuning is not addressed as the testing was done using a small testdataset
- Manual workarounds were not required

---

## 5. Summary

- [x] Overall completion status for both pipelines
- [x] Consolidated list of identified gaps (pipeline + documentation), each with a suggested owner/next step
- [x] Follow-up issues filed for any gaps that need separate tracking
