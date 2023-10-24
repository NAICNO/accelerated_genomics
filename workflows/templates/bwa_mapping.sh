#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

# Divide task memory by the number of CPUs
SAM_MEM=\$((${task.memory.giga} / ${task.cpus}))

## Run BWA MEM
### Source: https://github.com/nf-core/sarek/blob/f034b737630972e90aeae851e236f9d4292b9a4f/modules/nf-core/bwa/mem/main.nf#L30
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
    -o ${S_NAME}_bwa-mem_${PROCESSOR}.bam -

samtools index -@${task.cpus} -b ${S_NAME}_bwa-mem_${PROCESSOR}.bam