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
    -EV CompOverlap \
    -EV IndelSummary \
    -EV TiTvVariantEvaluator \
    -EV CountVariants \
    -EV MultiallelicSummary \
    -O cohortEval.txt
