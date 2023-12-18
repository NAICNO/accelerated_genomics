#!/bin/bash

set -euo pipefail

## Run Samtools flagstat

samtools flagstat -@${task.cpus} -b ${S_NAME}_samtools_flagstat_${PROCESSOR}.txt