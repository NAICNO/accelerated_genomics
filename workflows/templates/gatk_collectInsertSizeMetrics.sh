#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}


## Summary of insert-size metrics from BAM file
gatk --java-options  "-XX:-UsePerfData" \
    CollectInsertSizeMetrics \
    -I ${BAM} \
    -O ${BAM}.insert_size_metrics.txt \
    -H ${BAM}.insert_size_histogram.pdf 
