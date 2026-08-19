#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}


if [ -f ${TARGET_REGIONS} ]; then
    INTERVALS="--by ${TARGET_REGIONS}" 
else
	awk 'BEGIN{OFS="\\t"}{if ((\$2 !~ /_/) && (\$1 !~ /HD/) ) {split(\$2,a,":"); split(a[2],b,"_"); split(\$3,c,":"); print b[1], 1, c[2]}}' \${FASTA} > intervals.bed
    INTERVALS="--by intervals.bed"
fi

mosdepth \
	-n \
	--threads ${task.cpus} \
	\${INTERVALS} \
	--thresholds 1,10,20,30,50,100,150,200,250,300 \
	"mosdepth" \
	${BAM}