#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}


## Summary of insert-size metrics from BAM file
gatk --java-options  "-Xmx${task.memory.giga}g -Xms${task.memory.giga}g -XX:-UsePerfData" \
    CollectInsertSizeMetrics \
    -I ${BAM} \
    -O ${BAM}.insert_size_metrics.txt
