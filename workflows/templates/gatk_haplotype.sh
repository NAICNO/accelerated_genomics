#!/bin/bash

set -euo pipefail

FASTA=${REF}"/Homo_sapiens_assembly38.fasta"

gatk --java-options -Xmx${task.memory.giga}g \
    HaplotypeCaller \
    --input ${BAM} \
    --output ${BAM}.vcf \
    --reference \${FASTA} \
    --native-pair-hmm-threads ${task.cpus}