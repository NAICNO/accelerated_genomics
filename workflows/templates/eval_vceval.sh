#!/bin/bash

## https://gatk.broadinstitute.org/hc/en-us/articles/360040507171-VariantEval-BETA-#--eval-module

gatk --java-options "-XX:-UsePerfData"  VariantEval \
    -R Homo_sapiens_assembly38.fasta \
    -eval ${VCF} \
    -D Homo_sapiens_assembly38.dbsnp138.vcf \
    no-ev -noST \
    -EV CompOverlap -EV IndelSummary -EV TiTvVariantEvaluator \
    -EV CountVariants -EV MultiallelicSummary \
    -o cohortEval.txt
