#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

## Run ApplyBQSR Step
gatk --java-options -Xmx${task.memory.giga}g \
    ApplyBQSR \
    -R \${FASTA} \
    -I ${BAM} \
    --bqsr-recal-file ${RECAL} \
    -O ${BAM}_BQSR.bam