#!/bin/bash

# Run the workflow on the test data, and write the output to output/
bash nextflow-23.04.4-all \
    run \
    germline_pipeline.nf \
    -profile singularity \
    --fastq_folder /itf-fi-ml/home/pubuduss/sample_data/parabricks_sample/Data/fmted \
    --genome_folder /itf-fi-ml/home/pubuduss/sample_data/parabricks_sample/Ref \
    --genome_json parabricks_testref.json \
    --processor GPU \
    -with-report \
    -with-trace \
    -resume
