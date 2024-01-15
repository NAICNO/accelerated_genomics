#!/bin/bash

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
DICT=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--TARGET_INTERVALS ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

IFS="_" read -ra elements <<< ${TARGET_REGIONS}

gatk --java-options "-XX:-UsePerfData"  CollectVariantCallingMetrics \
    -I ${VCF} \
    --DBSNP ${DBSNP} \
    --THREAD_COUNT ${task.cpus} \
    \$INTERVALS \
    -SD \${DICT} \
    -O "VC_metrics_"\${elements[0]} 
