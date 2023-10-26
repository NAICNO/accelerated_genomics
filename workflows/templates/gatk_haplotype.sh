#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

## Variant calling with HaplotypeCaller
gatk --java-options  "-Xmx${task.memory.giga}g -XX:-UsePerfData -Xms${task.memory.giga}g -Xss3m -XX:-UsePerfData" \
    HaplotypeCaller \
    --input ${BAM} \
    --output ${BAM}.vcf \
    \${INTERVALS} \
    --reference \${FASTA} \
    --native-pair-hmm-threads ${task.cpus}