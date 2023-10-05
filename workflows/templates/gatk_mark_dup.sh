#!/bin/bash

set -euo pipefail

gatk --java-options -Xmx${task.memory.giga}g \
    MarkDuplicates \
    --VALIDATION_STRINGENCY SILENT \
    -I ${BAM} \
    -O ${BAM}_markdup.bam \
    -M metrics.txt \
    --TMP_DIR=temp_dir