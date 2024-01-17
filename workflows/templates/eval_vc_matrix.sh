#!/bin/bash

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}
DICT=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}
FAI=${REF}"/"${REF_MAP["reference_fasta"]["fai"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--TARGET_INTERVALS ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

# gatk --java-options "-XX:-UsePerfData"  CollectVariantCallingMetrics \
#     -I ${VCF} \
#     --DBSNP ${DBSNP} \
#     --THREAD_COUNT ${task.cpus} \
#     \$INTERVALS \
#     -SD \${DICT} \
#     -O "VariantCallingMetrics_"${VCF}

gatk --java-options "-XX:-UsePerfData"  VariantEval     \
    -R ${FASTA} \
    -eval ${VCF} \
    -D ${DBSNP} \
    -L ${TARGET_REGIONS} \
    -EV VCMetrics_CompOverlap_${VCF} \
    -EV VCMetrics_IndelSummary_${VCF} \
    -EV VCMetrics_TiTvVariantEvaluator_${VCF} \
    -EV VCMetrics_CountVariants_${VCF} \
    -EV VCMetrics_MultiallelicSummary_${VCF} \
    -O VCMetrics_cohortEval${VCF}
