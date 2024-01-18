#!/bin/bash

bgzip ${VCF} && tabix -p vcf ${VCF}.gz

gatk --java-options "-XX:-UsePerfData"  SelectVariants \
--exclude-filtered \
-V ${VCF}.gz \
-O ${VCF}.PASS.vcf
