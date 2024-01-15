#!/bin/bash

# (How to) Filter variants either with VQSR or by hard-filtering - GATK - Broad Institute Knowledge Base
## https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering#:~:text=By%20default%2C%20GATK%20HaplotypeCaller%20and,with%20QUAL%20less%20than%2030.

## Subset to SNPs-only callset
gatk  --java-options  "-XX:-UsePerfData" SelectVariants \
    -V ${HC_VCF} \
    -select-type SNP \
    -O snps.vcf.gz

## Subset to InDel-only callset with
gatk  --java-options  "-XX:-UsePerfData" SelectVariants \
    -V ${HC_VCF} \
    -select-type INDEL \
    -O indels.vcf.gz

## Hard-filter SNPs on multiple expressions using VariantFiltration

gatk  --java-options  "-XX:-UsePerfData" VariantFiltration \
    -V snps.vcf.gz \
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "QUAL < 30.0" --filter-name "QUAL30" \
    -filter "SOR > 3.0" --filter-name "SOR3" \
    -filter "FS > 60.0" --filter-name "FS60" \
    -filter "MQ < 40.0" --filter-name "MQ40" \
    -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
    -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
    -O snps_filtered.vcf.gz

## Hard-filter InDels on multiple expressions using VariantFiltration
gatk  --java-options  "-XX:-UsePerfData" VariantFiltration \ 
    -V indels.vcf.gz \ 
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "QUAL < 30.0" --filter-name "QUAL30" \
    -filter "FS > 200.0" --filter-name "FS200" \
    -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \ 
    -O indels_filtered.vcf.gz

## Merge filtered SNP and INDEL vcfs back together

gatk  --java-options  "-XX:-UsePerfData" MergeVcfs \
-I snps_filtered.vcf.gz \
-I indels_filtered.vcf.gz \
-O ${HC_VCF}.filtered.vcf

## Extract PASS variants only

gatk --java-options "-XX:-UsePerfData"  SelectVariants \
--exclude-filtered \
-V ${HC_VCF}.filtered.vcf \
-O ${HC_VCF}.filtered.PASS.vcf
