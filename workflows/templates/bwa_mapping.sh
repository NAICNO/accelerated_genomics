#!/bin/bash

set -euo pipefail

FASTA=${REF}"/Homo_sapiens_assembly38.fasta"

# Run BWA MEM
bwa mem \
    -t ${task.cpus} \
    -K 10000000 \
    -R "@RG\tID:${S_NAME}_rg1\tLB:lib1\tPL:bar\tSM:${S_NAME}\tPU:${S_NAME}_rg1" \
    \${FASTA} \
    ${R1} \
    ${R2} > ${S_NAME}_bwa-mem_${PROCESSOR}.sam