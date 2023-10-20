#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

# Divide task memory by the number of CPUs
SAM_MEM=\$((${task.memory.giga} / ${task.cpus}))

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
    -m\${SAM_MEM}g \
    -o ${S_NAME}_bwa-mem_${PROCESSOR}.bam -

samtools index -@${task.cpus} -m\${SAM_MEM}g -b ${S_NAME}_bwa-mem_${PROCESSOR}.bam