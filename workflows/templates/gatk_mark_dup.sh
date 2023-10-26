#!/bin/bash

set -euo pipefail

## Mark duplicated reads in BAM file
gatk --java-options  "-Xmx${task.memory.giga}g -XX:-UsePerfData -Xms${task.memory.giga}g -Xss3m -XX:-UsePerfData" \
    MarkDuplicates \
    --VALIDATION_STRINGENCY SILENT \
    -I ${BAM} \
    -O ${BAM}_markdup.bam \
    -M metrics.txt \
    --TMP_DIR=temp_dir

samtools index ${BAM}_markdup.bam