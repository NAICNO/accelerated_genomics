#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

## Run ApplyBQSR Step
gatk --java-options  "-Xmx${task.memory.giga}g -XX:-UsePerfData -Xms${task.memory.giga}g -Xss3m -XX:-UsePerfData" \
    ApplyBQSR \
    -R \${FASTA} \
    -I ${BAM} \
    --bqsr-recal-file ${RECAL} \
    -O ${BAM}_BQSR.bam