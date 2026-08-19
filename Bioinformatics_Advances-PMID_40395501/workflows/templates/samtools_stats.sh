#!/bin/bash

set -euo pipefail

## Run Samtools flagstat

samtools stat -@ ${task.cpus} ${BAM} > ${BAM}_samtools_stat_${PROCESSOR}.txt
