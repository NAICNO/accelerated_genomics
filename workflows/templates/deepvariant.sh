#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--regions ${TARGET_REGIONS}"
    MODEL="--model_type WES"
else 
    INTERVALS=""
    MODEL="--model_type WGS"
fi

/opt/deepvariant/bin/run_deepvariant \
    --ref ${FASTA} \
    --reads ${BAM} \
    --output_vcf ${BAM}.deepvariant.vcf.gz \
    --output_gvcf=${prefix}.g.vcf.gz \
    \${INTERVALS} \
    \${MODEL} \ \
    --intermediate_results_dir intermediate_results \
    --logging_dir logs_dir \
    --num_shards=${task.cpus}
