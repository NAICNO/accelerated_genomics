#!/bin/bash

OUT_FILE="${SOURCE.baseName}.${TYPE}.bed"

if [ -f ${QUERY} ]; then
    bedtools intersect -a ${SOURCE} -b ${QUERY} > \${OUT_FILE}
else
    cp ${SOURCE} \${OUT_FILE}
fi
