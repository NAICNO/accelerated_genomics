# Smoke Test before merging feature-brach

```bash
# 1. The actual collision case: default (WGS, no --pon) — NO_FILE_INTERVAL,
#    NO_FILE_PON, and NO_FILE_PON_TBI all land in the same MUTECTCALLER_STUB task.
#    Watch for: task completes without a staging error, and the echoed line has
#    neither --pon nor --interval-file.
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wgs

# 2. pon real, interval on the placeholder
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wgs --pon /any/path/pon.vcf.gz

# 3. interval real, pon on the placeholder (matches what the 2026-09-11 real-cluster
#    run on Fox/TSD actually exercised)
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wes --interval_file /any/path/targets.bed

# 4. both real, no placeholders at all
nextflow run nf_exome_interval_smoketest.nf --sequencing_type wes --interval_file /any/path/targets.bed --pon /any/path/pon.vcf.gz
```

```none
$ ../../../.././nextflow-26.08.0-edge-dist run nf_exome_interval_smoketest.nf --sequencing_type wgs

 N E X T F L O W   ~  version 26.08.0-edge

Launching `nf_exome_interval_smoketest.nf` [trusting_mcnulty] revision: 64d6c7022e

executor >  local (7)
[0b/8ddbbc] FQ2BAM_STUB          [100%] 1 of 1 ✔
[a6/8b1c8c] BQSR_STUB            [100%] 1 of 1 ✔
[9c/3a5df9] APPLYBQSR_STUB       [100%] 1 of 1 ✔
[ef/d432f3] HAPLOTYPECALLER_STUB [100%] 1 of 1 ✔
[51/70261b] DEEPVARIANT_STUB     [100%] 1 of 1 ✔
[20/3209bf] MUTECTCALLER_STUB    [100%] 1 of 1 ✔
[b8/178d32] DEEPSOMATIC_STUB     [100%] 1 of 1 ✔
MUTECTCALLER_STUB pbrun mutectcaller --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM   --out-vcf OUT.vcf.gz
APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam BAM --in-recal-file TABLE  --out-bam OUT.bam
HAPLOTYPECALLER_STUB pbrun haplotypecaller --ref REF --in-bam BAM  --out-variants OUT.vcf
BQSR_STUB pbrun bqsr --ref REF --in-bam BAM  --out-recal-file OUT.table
FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq R1 R2 --out-bam OUT.bam
DEEPSOMATIC_STUB pbrun deepsomatic --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM --mode shortread   --out-variants OUT.vcf
DEEPVARIANT_STUB pbrun deepvariant --ref REF --in-bam BAM --mode shortread   --out-variants OUT.vcf

$ ../../../.././nextflow-26.08.0-edge-dist run nf_exome_interval_smoketest.nf --sequencing_type wgs --pon /any/path/pon.vcf.gz

 N E X T F L O W   ~  version 26.08.0-edge

Launching `nf_exome_interval_smoketest.nf` [hopeful_minsky] revision: 64d6c7022e

executor >  local (7)
[85/cbd815] FQ2BAM_STUB          [100%] 1 of 1 ✔
[13/3766d1] BQSR_STUB            [100%] 1 of 1 ✔
[7a/900349] APPLYBQSR_STUB       [100%] 1 of 1 ✔
[f8/f4f1ec] HAPLOTYPECALLER_STUB [100%] 1 of 1 ✔
[1c/a1c6ad] DEEPVARIANT_STUB     [100%] 1 of 1 ✔
[41/f264ec] MUTECTCALLER_STUB    [100%] 1 of 1 ✔
[ee/2d2ac6] DEEPSOMATIC_STUB     [100%] 1 of 1 ✔
FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq R1 R2 --out-bam OUT.bam
APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam BAM --in-recal-file TABLE  --out-bam OUT.bam
HAPLOTYPECALLER_STUB pbrun haplotypecaller --ref REF --in-bam BAM  --out-variants OUT.vcf
BQSR_STUB pbrun bqsr --ref REF --in-bam BAM  --out-recal-file OUT.table
MUTECTCALLER_STUB pbrun mutectcaller --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM --pon pon.vcf.gz  --out-vcf OUT.vcf.gz
DEEPVARIANT_STUB pbrun deepvariant --ref REF --in-bam BAM --mode shortread   --out-variants OUT.vcf
DEEPSOMATIC_STUB pbrun deepsomatic --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM --mode shortread   --out-variants OUT.vcf

$ ../../../.././nextflow-26.08.0-edge-dist run nf_exome_interval_smoketest.nf --sequencing_type wes --interval_file /any/path/targets.bed

 N E X T F L O W   ~  version 26.08.0-edge

Launching `nf_exome_interval_smoketest.nf` [loquacious_curie] revision: 64d6c7022e

executor >  local (7)
[d8/2da28b] FQ2BAM_STUB          [100%] 1 of 1 ✔
[37/d58a3c] BQSR_STUB            [100%] 1 of 1 ✔
[98/9ee4a7] APPLYBQSR_STUB       [100%] 1 of 1 ✔
[a4/e78d72] HAPLOTYPECALLER_STUB [100%] 1 of 1 ✔
[85/6114b4] DEEPVARIANT_STUB     [100%] 1 of 1 ✔
[7e/0b5bba] MUTECTCALLER_STUB    [100%] 1 of 1 ✔
[d6/b76020] DEEPSOMATIC_STUB     [100%] 1 of 1 ✔
HAPLOTYPECALLER_STUB pbrun haplotypecaller --ref REF --in-bam BAM --interval-file targets.bed --out-variants OUT.vcf
APPLYBQSR_STUB pbrun applybqsr --ref REF --in-bam BAM --in-recal-file TABLE --interval-file targets.bed --out-bam OUT.bam
BQSR_STUB pbrun bqsr --ref REF --in-bam BAM --interval-file targets.bed --out-recal-file OUT.table
MUTECTCALLER_STUB pbrun mutectcaller --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM  --interval-file targets.bed --out-vcf OUT.vcf.gz
FQ2BAM_STUB pbrun fq2bam --ref REF --in-fq R1 R2 --out-bam OUT.bam
DEEPSOMATIC_STUB pbrun deepsomatic --ref REF --in-tumor-bam TBAM --in-normal-bam NBAM --mode shortread --use-wes-model --interval-file targets.bed --out-variants OUT.vcf
DEEPVARIANT_STUB pbrun deepvariant --ref REF --in-bam BAM --mode shortread --use-wes-model --interval-file targets.bed --out-variants OUT.vcf

```