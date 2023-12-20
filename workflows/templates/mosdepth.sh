#!/bin/bash

set -euo pipefail

FASTA=${REF}"/"${REF_MAP["reference_fasta"]["dict"]}

awk '{if ((\$2 !~ /_/) && (\$1 !~ /HD/) ) {split(\$2,a,":"); split(a[2],b,"_"); split(\$3,c,":"); print b[1], c[2]}}' \${FASTA} > intervals.bed

mosdepth \
	-n \
	--threads ${task.cpus} \
	--by intervals.bed \
	--thresholds 1,10,20,30,50,100,150,200,250,300 \
	"mosdepth" \
	${BAM}