#!/bin/bash

## https://gatk.broadinstitute.org/hc/en-us/articles/360040507171-VariantEval-BETA-#--eval-module

gatk --java-options "-XX:-UsePerfData"  VariantEval \
    -R Homo_sapiens_assembly38.fasta \
    -eval GPU_head.vcf.filtered.PASS.vcf.gz \
    -D Homo_sapiens_assembly38.dbsnp138.vcf \
    no-ev -noST \
    -EV CompOverlap -EV IndelSummary -EV TiTvVariantEvaluator \
    -EV CountVariants -EV MultiallelicSummary \
    -o cohortEval.txt

gatk --java-options "-XX:-UsePerfData"  VariantEval     \
    -R GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
    -eval GPU_head.vcf.filtered.PASS.vcf.gz \
    -D Homo_sapiens_assembly38.dbsnp138_1.vcf \
    -EV CompOverlap \
    -EV IndelSummary \
    -EV TiTvVariantEvaluator \
    -EV CountVariants \
    -EV MultiallelicSummary \
    -O cohortEval.txt


## chr<digit|string>_<digit|string>
## gsutil cp gs://genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf .
grep -vE "chr[0-9a-zA-Z]+_[0-9a-zA-Z]+" Homo_sapiens_assembly38.dbsnp138.vcf | grep -vE "HLA|EBV|chrM" > Homo_sapiens_assembly38.dbsnp138_CHROMS.vcf
