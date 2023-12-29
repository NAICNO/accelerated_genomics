#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--intervals ${TARGET_REGIONS}"
    ## Variant calling with DeepVariant
    /opt/deepvariant/bin/run_deepvariant \
        --ref=${FASTA} \
        --reads=${BAM} \
        --output_vcf=${prefix}.vcf.gz \
        --output_gvcf=${prefix}.g.vcf.gz \
        \${INTERVALS} \
        --model_type WES \
        --intermediate_results_dir=. \
        --num_shards=${task.cpus}
else 
    ## Variant calling with DeepVariant
    /opt/deepvariant/bin/run_deepvariant \
        --ref=${FASTA} \
        --reads=${BAM} \
        --output_vcf=${prefix}.vcf.gz \
        --output_gvcf=${prefix}.g.vcf.gz \
        --model_type WGS \
        --intermediate_results_dir=. \
        --num_shards=${task.cpus}
fi
