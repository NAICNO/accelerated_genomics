#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}


## Summary of alignment metrics from BAM file
gatk --java-options  "-Xmx${task.memory.giga}g -Xms${task.memory.giga}g -XX:-UsePerfData" \
    CollectAlignmentSummaryMetrics \
    -R \${FASTA} \
    -I ${BAM} \
    -O ${BAM}.alignment_summary_metrics.txt
