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
    CollectInsertSizeMetrics \
    --input ${BAM} \
    --output ${BAM}.insert_size_metrics.txt \

## H=insert_size_histogram.pdf \
## M=0.5