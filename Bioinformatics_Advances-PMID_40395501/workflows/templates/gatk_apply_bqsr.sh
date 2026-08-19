#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

## Run ApplyBQSR Step
gatk --java-options  "-XX:-UsePerfData" \
    ApplyBQSR \
    -R \${FASTA} \
    -I ${BAM} \
    \${INTERVALS} \
    --bqsr-recal-file ${RECAL} \
    -O ${BAM}_BQSR.bam