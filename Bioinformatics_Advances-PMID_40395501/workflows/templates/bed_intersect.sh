#!/bin/bash

OUT_FILE="${SOURCE.baseName}.${TYPE}.bed"
DICT=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}


if [ -f ${QUERY} ]; then
    bedtools intersect -a ${SOURCE} -b ${QUERY} > \${OUT_FILE}
else
    cp ${SOURCE} \${OUT_FILE}
fi

## https://gatk.broadinstitute.org/hc/en-us/community/posts/360063906772-GATK4-1-7-0-specific-error-htsjdk-samtools-SAMException-Cannot-read-non-existent-file-
gatk --java-options "-XX:-UsePerfData" BedToIntervalList \
    --INPUT \${OUT_FILE} \
    --OUTPUT \${OUT_FILE}.intervals_list \
    --SEQUENCE_DICTIONARY \${DICT}
