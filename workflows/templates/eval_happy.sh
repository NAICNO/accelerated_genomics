#!/bin/bash

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["fna"]}

if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="-f ${TARGET_REGIONS}" 
else 
    INTERVALS=""
fi

IFS="_" read -ra elements <<< ${TARGET_REGIONS}

hap.py ${VCF} ${QUERY_VCF} \${INTERVALS} \
    -o "VC_"\${elements[0]} \
    -r \${FASTA} \
    --threads ${task.cpus}
