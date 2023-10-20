#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

## Run BWA MEM
bwa mem \
    -t ${task.cpus} \
    -K 10000000 \
    -R "@RG\\tID:${S_NAME}_rg1\\tLB:lib1\\tPL:bar\\tSM:${S_NAME}\\tPU:${S_NAME}_rg1" \
    \${FASTA} \
    ${R1} \
    ${R2} \
    | samtools \
    sort \
    -@${task.cpus} \
    -m${task.memory.giga}g \
    -o ${S_NAME}_bwa-mem_${PROCESSOR}.bam -

samtools index -@4 -m4g -b ${S_NAME}_bwa-mem_${PROCESSOR}.bam