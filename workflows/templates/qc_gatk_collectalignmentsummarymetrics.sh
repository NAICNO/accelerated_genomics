#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

## Variant calling with HaplotypeCaller
gatk --java-options  "-Xmx${task.memory.giga}g -Xms${task.memory.giga}g -XX:-UsePerfData" \
    CollectAlignmentSummaryMetrics \
    --reference \${FASTA} \
    --input ${BAM} \
    --output ${BAM}.alignment_summary_metrics.txt \
