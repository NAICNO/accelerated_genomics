#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}


## Summary of alignment metrics from BAM file
gatk --java-options  "-XX:-UsePerfData" \
    CollectAlignmentSummaryMetrics \
    -R \${FASTA} \
    -I ${BAM} \
    -O ${BAM}.alignment_summary_metrics.txt
