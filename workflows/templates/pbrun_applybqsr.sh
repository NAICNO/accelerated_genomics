#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--interval-file ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

pbrun applybqsr --ref \${FASTA} \
--in-bam ${BAM} \
--num-gpus 1 \
\${INTERVALS} \
--in-recal-file ${RECAL} \
--out-bam  "${BAM}._applybqsr.bam.bam"