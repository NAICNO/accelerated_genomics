#!/bin/bash

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

bgzip ${VCF} && tabix -p vcf ${VCF}.gz
bgzip ${QUERY_VCF} && tabix -p vcf ${QUERY_VCF}.gz

gatk --java-options "-XX:-UsePerfData" GenotypeConcordance \
    --CALL_VCF ${QUERY_VCF}.gz \
    \${INTERVALS} \
    --OUTPUT "GenotypeConcordance_"${VCF}.gz \
    --TRUTH_VCF ${VCF}
