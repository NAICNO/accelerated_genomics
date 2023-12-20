#!/bin/bash

set -euo pipefail

## Run Samtools flagstat

samtools flagstat -@ ${task.cpus} ${BAM} > ${BAM}_samtools_flagstat_${PROCESSOR}.txt