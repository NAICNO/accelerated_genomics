#!/bin/bash

# Run the workflow on the test data, and write the output to output/
bash nextflow-23.04.4-all \
    run \
    germline_cpu.nf \
    -profile standard \
    --fastq_folder /Users/pubuduss/Developer/com/ngs-pipe-cpu/test_data/fq \
    --genome_folder /Users/pubuduss/Developer/com/ngs-pipe-cpu/test_data/ref \
    --genome_json reference_data.json \
    -with-report \
    -with-trace \
    -resume
