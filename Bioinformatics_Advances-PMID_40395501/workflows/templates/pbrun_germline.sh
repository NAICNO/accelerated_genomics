#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

pbrun germline --ref \${FASTA} \
    --in-fq ${R1} ${R2} \
    --knownSites \${KNOWN_SITES} \
    --out-bam ${S_NAME}_fpbrun_germline_${PROCESSOR}.bam \
    --out-variants ${S_NAME}_fpbrun_germline_${PROCESSOR}.vcf \
    --out-recal-file ${S_NAME}_fpbrun_germline_${PROCESSOR}.txt
