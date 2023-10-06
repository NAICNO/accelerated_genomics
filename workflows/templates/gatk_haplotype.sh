#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

## Variant calling with HaplotypeCaller
gatk --java-options -Xmx${task.memory.giga}g \
    HaplotypeCaller \
    --input ${BAM} \
    --output ${BAM}.vcf \
    --reference \${FASTA} \
    --native-pair-hmm-threads ${task.cpus}