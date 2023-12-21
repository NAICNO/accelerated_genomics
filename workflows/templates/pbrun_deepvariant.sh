#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--interval-file ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

pbrun deepvariant --ref \${FASTA} \
--in-bam ${BAM} \
--num-gpus ${task.gpu} \
\${INTERVALS} \
--out-variants  "${BAM}.deepvariant.vcf"