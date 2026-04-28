#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--interval-file ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

BAM_NORMAL_NAME=$(basename "${BAM_NORMAL}" .bam)
BAM_TUMOR_NAME=$(basename "${BAM_TUMOR}" .bam)
OUTPUT_VCF="${PAIR_ID}.mutect.vcf"

pbrun mutectcaller --ref \${FASTA} \
--num-gpus ${task.gpu} \
\${INTERVALS} \
--tumor-name ${BAM_TUMOR_NAME} \
--in-tumor-bam ${BAM_TUMOR} \
--in-normal-bam ${BAM_NORMAL} \
--normal-name ${BAM_NORMAL_NAME} \
--out-vcf ${OUTPUT_VCF}
