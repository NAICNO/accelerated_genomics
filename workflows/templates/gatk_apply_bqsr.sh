#!/bin/bash

set -euo pipefail

FASTA=${REF}"/Homo_sapiens_assembly38.fasta"

### Run ApplyBQSR Step
gatk --java-options -Xmx${task.memory.giga}g \
    ApplyBQSR \
    -R \${FASTA} \
    -I ${BAM} \
    --bqsr-recal-file ${RECAL} \
    -O ${BAM}_BQSR.bam