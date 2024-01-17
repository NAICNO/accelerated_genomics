#!/bin/bash

bgzip ${VCF} && tabix -p vcf ${VCF}.gz
bgzip ${QUERY_VCF} && tabix -p vcf ${QUERY_VCF}.gz

gatk --java-options "-XX:-UsePerfData" GenotypeConcordance \
    --CALL_VCF ${QUERY_VCF}.gz \
    --INTERVALS ${TARGET_REGIONS} \
    --OUTPUT "GenotypeConcordance_"${VCF} \
    --TRUTH_VCF ${VCF}.gz
