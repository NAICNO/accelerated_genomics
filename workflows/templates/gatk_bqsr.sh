#!/bin/bash

set -euo pipefail

FASTA=${REF}"/Homo_sapiens_assembly38.fasta"
KNOWN_SITES=${REF}"/Homo_sapiens_assembly38.known_indels.vcf.gz"

### Generate BQSR Report
gatk --java-options -Xmx${task.memory.giga}g \
    BaseRecalibrator \
    --input ${BAM} \
    --output ${S_NAME}_${PROCESSOR}_recal.txt \
    --known-sites \${KNOWN_SITES} \
    --reference \${FASTA}