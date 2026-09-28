# Giraffe Tier 2 — Fox runbook results

## Step 0 — session setup

## Step 1 — static checks on the pushed code (login node, seconds)

```none
# `check_module_sync.sh | tail -1`
GREEN: real code matches nf_giraffe_arg_smoketest.nf's stubs.

# `check_stub_sync.sh`
OK: stub process list and labels match modules/*.nf (11 processes).

# `nextflow -q -c germline.config config -profile singularity,fox,test -o flat` | grep -E "germline_mapping|withName:GIRAFFE" 
params.germline_mapping = 'fq2bam'
process.'withName:GIRAFFE'.cpus = 16
process.'withName:GIRAFFE'.time = '10m'
process.'withName:GIRAFFE'.ext.mem_gb = 256
```

**Resource sweep:**

```none
# nf_resource_sweep_verification.nf -c nf_resource_sweep_verification.config -profile fox,test

Nextflow 26.09.1-edge is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.08.0-edge

Launching `nf_resource_sweep_verification.nf` [loquacious_babbage] revision: 9a4ea47b62

executor >  slurm (10)
[8a/2c05fc] FQ2BAM          [100%] 1 of 1 ✔
[60/9d65f5] BQSR            [100%] 1 of 1 ✔
[84/6226b0] APPLYBQSR       [100%] 1 of 1 ✔
[f7/7f618c] MUTECTCALLER    [100%] 1 of 1 ✔
[aa/484faa] DEEPSOMATIC     [100%] 1 of 1 ✔
[67/2e303a] DEEPVARIANT     [100%] 1 of 1 ✔
[54/3775b0] HAPLOTYPECALLER [100%] 1 of 1 ✔
[bd/718b0b] PREPON          [100%] 1 of 1 ✔
[22/fe555f] POSTPON         [100%] 1 of 1 ✔
[ca/008936] VCFQC           [100%] 1 of 1 ✔
Wrote resource sweep results to: ./resource_sweep_results.tsv
```

***`nf_resource_sweep_verification.nf` didn't run Giraffe process***

## Step 2 — build the 24-contig reference

```none
# verify `vg_v1.70.0.sif` and `tiny_ref/Homo_sapiens_assembly38.primary.paths`
-rwxrwx---+ 1 ec-pubuduss ec232-member-group       133 Sep 22 15:47 tiny_ref/Homo_sapiens_assembly38.primary.paths
-rwxrwx---+ 1 ec-pubuduss ec232-member-group 244826112 Sep 21 15:30 vg_v1.70.0.sif

grep CHECK giraffe_primary_ref-*.out
CHECK 1 contigs/order == primary.paths: OK
CHECK 2 sequences == source FASTA: DIFFER -- do not use for Tier 2, investigate

# diff <(samtools view ...
OK: ref .fai == Tier 1 @SQ

# Homo_sapiens_assembly38.primary.gbz.{fa,fa.fai,dict}
-rwxrwx---+ 1 ec-pubuduss ec232-member-group       4636 Sep 28 12:02 ../../../../girrfe_mapper/vg_mapping_exercises/tiny_ref/Homo_sapiens_assembly38.primary.gbz.dict
-rwxrwx---+ 1 ec-pubuduss ec232-member-group 3126873374 Sep 28 12:02 ../../../../girrfe_mapper/vg_mapping_exercises/tiny_ref/Homo_sapiens_assembly38.primary.gbz.fa
-rwxrwx---+ 1 ec-pubuduss ec232-member-group        760 Sep 28 12:02 ../../../../girrfe_mapper/vg_mapping_exercises/tiny_ref/Homo_sapiens_assembly38.primary.gbz.fa.fai
```

## Step 4 — real-pipeline fail-fast + DAG

```none
# $NF -params-file params.giraffe_fox.yaml -with-dag dag_giraffe.mmd; echo "exit=$?"
exit=0

# grep -o '"[A-Z0-9_]*"' dag_giraffe.mmd | sort -u | tr '\n' ' '; echo
"APPLYBQSR" "BQSR" "DEEPVARIANT" "GIRAFFE" "HAPLOTYPECALLER" "VCFQC"

#  $NF -params-file params.fq2bam_fox.yaml  -with-dag dag_fq2bam.mmd;  echo "exit=$?"
exit=0

#  grep -o '"[A-Z0-9_]*"' dag_fq2bam.mmd  | sort -u | tr '\n' ' '; echo
"APPLYBQSR" "BQSR" "DEEPVARIANT" "FQ2BAM" "HAPLOTYPECALLER" "VCFQC"

# $NF -params-file params.nozip.tmp.yaml;                         echo "exit=$?"
germline_mapping = 'giraffe' requires: graph_zipcodes -- see params.germline.yaml.example for the giraffe branch.
exit=1

#  $NF -params-file params.fq2bam_fox.yaml --graph_min /x/g.min;   echo "exit=$?"
graph_min was given but germline_mapping is 'fq2bam' -- set --germline_mapping giraffe to actually use it, or drop it.
exit=1
```

## Step 5 — Tier 2 run: giraffe

```
 ${REPO}/../nextflow-26.08.0-edge-dist run "$REPO/AUS/germline_workflow.nf" -c "$REPO/AUS/germline.config" -profile singularity,fox,test -params-file params.giraffe_fox.yaml -with-report "report_giraffe_fox.html" -with-timeline "timeline_giraffe_fox.html" "$@"

Nextflow 26.09.1-edge is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.08.0-edge

Launching `/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS/germline_workflow.nf` [exotic_mahavira] revision: d02daced48

executor >  slurm (7)
[7c/0d18c8] GIRAFFE (SAMPLE01)               [100%] 1 of 1 ✔
[c7/89bbe2] BQSR (SAMPLE01)                  [100%] 1 of 1 ✔
[7c/5f2100] APPLYBQSR (SAMPLE01)             [100%] 1 of 1 ✔
[62/c4f132] DEEPVARIANT (SAMPLE01)           [100%] 1 of 1 ✔
[04/2facfb] HAPLOTYPECALLER (SAMPLE01)       [100%] 1 of 1 ✔
[4a/47d96b] VCFQC (SAMPLE01_haplotypecaller) [100%] 2 of 2 ✔
Completed at: 28-Sep-2026 13:04:12
Duration    : 7m 31s
CPU hours   : 1.9
Succeeded   : 7
```

**Run verify_tier2.sh:**

*Note: NextFlow was run from the submit node, not from using SLRUM job submission*.

```none
bash verify_tier2.sh giraffe

=== 1. every process COMPLETED (trace) ===
no trace_params.giraffe_fox.txt -- did the head job finish?

=== 2. published tree ===
results_tier2/bam/giraffe/SAMPLE01/SAMPLE01.bam
results_tier2/bam/giraffe/SAMPLE01/SAMPLE01.bam.bai
results_tier2/bam_recal/giraffe/SAMPLE01/SAMPLE01.recal.bam
results_tier2/bam_recal/giraffe/SAMPLE01/SAMPLE01.recal.bam.bai
results_tier2/qc/bam/giraffe/SAMPLE01/SAMPLE01.duplicate_metrics.txt
results_tier2/qc/vcf/giraffe/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt
results_tier2/qc/vcf/giraffe/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt
results_tier2/vcf/giraffe/deepvariant/SAMPLE01.deepvariant.vcf
results_tier2/vcf/giraffe/haplotypecaller/SAMPLE01.haplotypecaller.vcf

=== 3. BAM header: @PG and @SQ ===
@PG	ID:pbrun giraffe	PN:pbrun giraffe	VN:4.7.1-1	CL:pbrun giraffe --in-fq sample_normal_1.fastq.gz sample_normal_2.fastq.gz --gbz-name Homo_sapiens_assembly38.autoindex.1.70.giraffe.gbz --dist-name Homo_sapiens_assembly38.autoindex.1.70.dist --minimizer-name Homo_sapiens_assembly38.autoindex.1.70.shortread.withzip.min --zipcodes-name Homo_sapiens_assembly38.autoindex.1.70.shortread.zipcodes --ref-
@PG	ID:samtools	PN:samtools	PP:pbrun giraffe	VN:1.17	CL:samtools view -H results_tier2/bam/giraffe/SAMPLE01/SAMPLE01.bam
@SQ count: 24

=== 4. .command.sh of the aligner task (flags actually sent to pbrun) ===
awk: fatal: cannot open file `trace_params.giraffe_fox.txt' for reading: No such file or directory
cat: 'work/*/.command.sh': No such file or directory
work dir for GIRAFFE () not found

=== 5. BQSR task: known-sites / contig messages (context doc 3b) ===
awk: fatal: cannot open file `trace_params.giraffe_fox.txt' for reading: No such file or directory
grep: work/*/.command.log: No such file or directory
grep: work/*/.command.err: No such file or directory
BQSR work dir not found

=== 6. variant counts (non-header lines) ===
deepvariant:     91358
haplotypecaller: 73237

=== 7. bcftools stats summary (VCFQC) ===
results_tier2/qc/vcf/giraffe/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of records:	91358
results_tier2/qc/vcf/giraffe/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of SNPs:	72955
results_tier2/qc/vcf/giraffe/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of indels:	18418
results_tier2/qc/vcf/giraffe/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of records:	73237
results_tier2/qc/vcf/giraffe/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of SNPs:	60165
results_tier2/qc/vcf/giraffe/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of indels:	13148

```

## Step 7 — fq2bam baseline, same outdir

```none
${REPO}/../nextflow-26.08.0-edge-dist run "$REPO/AUS/germline_workflow.nf" -c "$REPO/AUS/germline.config" -profile singularity,fox,test -params-file params.fq2bam_fox.yaml -with-report "report_fq2bam_fox.html" -with-timeline "timeline_fq2bam_fox.html" "$@"
Nextflow 26.09.1-edge is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.08.0-edge

Launching `/projects/ec232/ngs/analysis/AUS/accelerated_genomics/AUS/germline_workflow.nf` [golden_lagrange] revision: d02daced48

executor >  slurm (7)
[c6/615c9b] FQ2BAM (SAMPLE01)                [100%] 1 of 1 ✔
[97/4b8b55] BQSR (SAMPLE01)                  [100%] 1 of 1 ✔
[51/7361ea] APPLYBQSR (SAMPLE01)             [100%] 1 of 1 ✔
[df/5957f6] DEEPVARIANT (SAMPLE01)           [100%] 1 of 1 ✔
[a3/727629] HAPLOTYPECALLER (SAMPLE01)       [100%] 1 of 1 ✔
[a8/59456c] VCFQC (SAMPLE01_deepvariant)     [100%] 2 of 2 ✔
Completed at: 28-Sep-2026 12:40:15
Duration    : 5m 36s
CPU hours   : 1.4
Succeeded   : 7

```

***Verify fq2bam***

*Note: NextFlow was run from the submit node, not from using SLRUM job submission*.

```none
# bash verify_tier2.sh fq2bam  2>&1 | tee verify_fq2bam.txt
=== 1. every process COMPLETED (trace) ===
no trace_params.fq2bam_fox.txt -- did the head job finish?

=== 2. published tree ===
results_tier2/bam/fq2bam/SAMPLE01/SAMPLE01.bam
results_tier2/bam/fq2bam/SAMPLE01/SAMPLE01.bam.bai
results_tier2/bam_recal/fq2bam/SAMPLE01/SAMPLE01.recal.bam
results_tier2/bam_recal/fq2bam/SAMPLE01/SAMPLE01.recal.bam.bai
results_tier2/qc/vcf/fq2bam/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt
results_tier2/qc/vcf/fq2bam/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt
results_tier2/vcf/fq2bam/deepvariant/SAMPLE01.deepvariant.vcf
results_tier2/vcf/fq2bam/haplotypecaller/SAMPLE01.haplotypecaller.vcf

=== 3. BAM header: @PG and @SQ ===
@PG	ID:pbrun fq2bam	PN:pbrun fq2bam	VN:4.7.1-1	CL:pbrun fq2bam --ref Homo_sapiens_assembly38.fasta --in-fq sample_normal_1.fastq.gz sample_normal_2.fastq.gz --out-bam SAMPLE01.bam --read-group-sm SAMPLE01 --num-gpus 1 --tmp-dir /fp/projects01/ec232/ngs/analysis/AUS/accelerated_genomics/AUS/tests/nf_giraffe_tier2_fox/work/c6/615c9b9e74ffc178a9f45e3287fdde/pbrun_tmp
@PG	ID:samtools	PN:samtools	PP:pbrun fq2bam	VN:1.17	CL:samtools view -H results_tier2/bam/fq2bam/SAMPLE01/SAMPLE01.bam
@SQ count: 3366

=== 4. .command.sh of the aligner task (flags actually sent to pbrun) ===
awk: fatal: cannot open file `trace_params.fq2bam_fox.txt' for reading: No such file or directory
cat: 'work/*/.command.sh': No such file or directory
work dir for FQ2BAM () not found

=== 5. BQSR task: known-sites / contig messages (context doc 3b) ===
awk: fatal: cannot open file `trace_params.fq2bam_fox.txt' for reading: No such file or directory
grep: work/*/.command.log: No such file or directory
grep: work/*/.command.err: No such file or directory
BQSR work dir not found

=== 6. variant counts (non-header lines) ===
deepvariant:     95166
haplotypecaller: 83043

=== 7. bcftools stats summary (VCFQC) ===
results_tier2/qc/vcf/fq2bam/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of records:	95166
results_tier2/qc/vcf/fq2bam/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of SNPs:	76143
results_tier2/qc/vcf/fq2bam/deepvariant/SAMPLE01.deepvariant.vcf_stats.txt:SN	0	number of indels:	19089
results_tier2/qc/vcf/fq2bam/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of records:	83043
results_tier2/qc/vcf/fq2bam/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of SNPs:	69056
results_tier2/qc/vcf/fq2bam/haplotypecaller/SAMPLE01.haplotypecaller.vcf_stats.txt:SN	0	number of indels:	14081

=== 8. flagstat ===
18596279 + 0 in total (QC-passed reads + QC-failed reads)
18578384 + 0 primary
0 + 0 secondary
17895 + 0 supplementary
163940 + 0 duplicates
163940 + 0 primary duplicates
18572680 + 0 mapped (99.87% : N/A)
18554785 + 0 primary mapped (99.87% : N/A)
```

***Verify and Compare:***

```none
# bash verify_tier2.sh compare 2>&1 | tee verify_compare.txt

=== giraffe vs fq2bam -- informational, not pass/fail (test graph has no haplotypes) ===
fq2bam   deepvariant      all=95166    chr21=94456
giraffe  deepvariant      all=91358    chr21=87315
fq2bam   haplotypecaller  all=83043    chr21=79390
giraffe  haplotypecaller  all=73237    chr21=72537
```

***Results files:***
```none
 tree -h results_tier2/
results_tier2/
├── [ 4.0K]  bam
│   ├── [ 4.0K]  fq2bam
│   │   └── [ 4.0K]  SAMPLE01
│   │       ├── [ 1.4G]  SAMPLE01.bam
│   │       └── [ 1.9M]  SAMPLE01.bam.bai
│   └── [ 4.0K]  giraffe
│       └── [ 4.0K]  SAMPLE01
│           ├── [ 1.3G]  SAMPLE01.bam
│           └── [ 1.7M]  SAMPLE01.bam.bai
├── [ 4.0K]  bam_recal
│   ├── [ 4.0K]  fq2bam
│   │   └── [ 4.0K]  SAMPLE01
│   │       ├── [ 1.3G]  SAMPLE01.recal.bam
│   │       └── [ 1.9M]  SAMPLE01.recal.bam.bai
│   └── [ 4.0K]  giraffe
│       └── [ 4.0K]  SAMPLE01
│           ├── [ 1.2G]  SAMPLE01.recal.bam
│           └── [ 1.7M]  SAMPLE01.recal.bam.bai
├── [ 4.0K]  pipeline_info
│   └── [  255]  trace.txt
├── [ 4.0K]  qc
│   ├── [ 4.0K]  bam
│   │   └── [ 4.0K]  giraffe
│   │       └── [ 4.0K]  SAMPLE01
│   │           └── [ 2.2K]  SAMPLE01.duplicate_metrics.txt
│   └── [ 4.0K]  vcf
│       ├── [ 4.0K]  fq2bam
│       │   ├── [ 4.0K]  deepvariant
│       │   │   └── [  18K]  SAMPLE01.deepvariant.vcf_stats.txt
│       │   └── [ 4.0K]  haplotypecaller
│       │       └── [ 193K]  SAMPLE01.haplotypecaller.vcf_stats.txt
│       └── [ 4.0K]  giraffe
│           ├── [ 4.0K]  deepvariant
│           │   └── [  18K]  SAMPLE01.deepvariant.vcf_stats.txt
│           └── [ 4.0K]  haplotypecaller
│               └── [ 159K]  SAMPLE01.haplotypecaller.vcf_stats.txt
└── [ 4.0K]  vcf
    ├── [ 4.0K]  fq2bam
    │   ├── [ 4.0K]  deepvariant
    │   │   └── [ 8.3M]  SAMPLE01.deepvariant.vcf
    │   └── [ 4.0K]  haplotypecaller
    │       └── [  17M]  SAMPLE01.haplotypecaller.vcf
    └── [ 4.0K]  giraffe
        ├── [ 4.0K]  deepvariant
        │   └── [ 7.8M]  SAMPLE01.deepvariant.vcf
        └── [ 4.0K]  haplotypecaller
            └── [  14M]  SAMPLE01.haplotypecaller.vcf
```
