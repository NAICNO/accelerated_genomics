#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

## Generate BQSR Report
gatk --java-options -Xmx${task.memory.giga}g \
    BaseRecalibrator \
    --input ${BAM} \
    --output ${S_NAME}_${PROCESSOR}_recal.txt \
    --known-sites \${KNOWN_SITES} \
    --reference \${FASTA}