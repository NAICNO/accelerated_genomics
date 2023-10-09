#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

pbrun haplotypecaller --ref \${FASTA} \
--in-bam ${BAM} \
--in-recal-file ${RECAL} \
--out-variants ${S_NAME}_pbrun_haplotypecaller_${PROCESSOR}.vcf