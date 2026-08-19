#!/bin/bash

set -euo pipefail

## Mark duplicated reads in BAM file
gatk --java-options  "-Xss3m -XX:-UsePerfData" \
    MarkDuplicates \
    --VALIDATION_STRINGENCY SILENT \
    -I ${BAM} \
    -O ${BAM}_markdup.bam \
    -M metrics.txt \
    --TMP_DIR temp_dir

samtools index ${BAM}_markdup.bam
