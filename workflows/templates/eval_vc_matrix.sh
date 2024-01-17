#!/bin/bash

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
DICT=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}
FAI=${REF}"/"${REF_MAP["reference_fasta"]["fai"]}
DBSNP=${REF}"/"${REF_MAP["DBSNP"]["vcf"]}
DBSNPIDX=${REF}"/"${REF_MAP["DBSNP"]["idx"]}

bgzip ${VCF} && tabix -p vcf ${VCF}.gz

gatk --java-options "-XX:-UsePerfData"  VariantEval     \
    -R \${FASTA} \
    -eval ${VCF}.gz \
    -D \${DBSNP} \
    -L ${TARGET_REGIONS} \
    -EV CompOverlap \
    -EV IndelSummary \
    -EV TiTvVariantEvaluator \
    -EV CountVariants \
    -EV MultiallelicSummary \
    -O VCMetrics_${VCF}