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
    CollectGcBiasMetrics \
    --reference \${FASTA} \
    --input ${BAM} \
    --output ${BAM}.GC_bias_metrics.txt \
    --CHART ${BAM}.gc_bias_metrics.pdf \
    --S ${BAM}.summary_metrics.txt
