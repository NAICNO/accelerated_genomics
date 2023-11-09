#!/bin/bash

set -euo pipefail

# Sort SAM file
gatk --java-options  "-Xmx${task.memory.giga}g -Xms${task.memory.giga}g -Xss3m -XX:-UsePerfData" \
    SortSam \
    --VALIDATION_STRINGENCY SILENT \
    --MAX_RECORDS_IN_RAM 5000000 \
    -I ${SAM} \
    -O ${SAM}.bam \
    --SORT_ORDER coordinate --TMP_DIR=temp_dir