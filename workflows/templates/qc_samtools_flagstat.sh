#!/bin/bash

set -euo pipefail

samtools -@${task.cpus} flagstat ${BAM} -o ${BAM}_flagstat.txt
