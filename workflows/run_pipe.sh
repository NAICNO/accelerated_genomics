#!/bin/bash

# Run the workflow on the test data, and write the output to output/
bash nextflow-23.04.4-all \
    run \
    germline_cpu.nf \
    -profile singularity \
    --fastq_folder /home/pubuduss/data/parabricks_sample/Data/dw_data \
    --genome_folder /home/pubuduss/data/parabricks_sample/Ref \
    -with-report \
    -with-trace \
    -resume
