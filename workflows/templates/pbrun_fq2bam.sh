#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
KNOWN_SITES=${REF}"/"${REF_MAP["known_sites_gold_standard"]["vcf"]}

pbrun fq2bam \
--ref \${FASTA} \
--in-fq ${R1} ${R2}  \
--knownSites \${KNOWN_SITES} \
--out-bam ${S_NAME}_pbrun_fq2bam_${PROCESSOR}.bam \
--out-recal-file ${S_NAME}_${PROCESSOR}_recal_gpu.txt \
--tmp-dir .