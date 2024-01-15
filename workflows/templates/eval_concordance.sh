#!/bin/bash

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

IFS="_" read -ra elements <<< ${TARGET_REGIONS}

gatk --java-options "-XX:-UsePerfData" GenotypeConcordance \
    --CALL_VCF ${VCF} \
    \${INTERVALS} \
    --OUTPUT "VC_"\${elements[0]} \
    --TRUTH_VCF ${QUERY_VCF}
