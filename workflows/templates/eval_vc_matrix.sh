#!/bin/bash

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
DICT=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--TARGET_INTERVALS ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

gatk --java-options "-XX:-UsePerfData"  CollectVariantCallingMetrics \
    -I ${VCF} \
    --DBSNP ${DBSNP} \
    --THREAD_COUNT ${task.cpus} \
    \$INTERVALS \
    -SD \${DICT} \
    -O "VariantCallingMetrics_"${VCF}
