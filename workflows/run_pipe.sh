#!/bin/bash

# Run the workflow on the test data, and write the output to output/
bash nextflow-23.04.4-all \
    run \
    germline_cpu.nf \
    -profile singularity \
    --fastq_folder /home/pubuduss/data/samples/parabricks_sample \
    --genome_folder /home/pubuduss/data/ngs/Ref \
    --genome_json parabricks_testref.json \
    -with-report \
    -with-trace \
    -resume
