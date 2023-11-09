#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

## Generate BQSR Report
gatk --java-options  "-Xmx${task.memory.giga}g -XX:-UsePerfData -Xms${task.memory.giga}g -XX:-UsePerfData" \
    BaseRecalibrator \
    --input ${BAM} \
    --output ${S_NAME}_${PROCESSOR}_recal.txt \
    \${INTERVALS} \
    --known-sites \${KNOWN_SITES} \
    --reference \${FASTA}