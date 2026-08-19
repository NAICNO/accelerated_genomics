#! /bin/bash

./nextflow run vc_eval.nf \
-profile singularity \
--sample_name NA12878_35x \
--VC_GPU GPU_head.vcf \
--VC_CPU CPU_head.vcf \
--genome_folder /scratch/pubuduss/ngs/GRCh38 \
--genome_json reference_data.json \
--target_regions chr1_HG001_GRCh38_1_22_v4.2.1_benchmark.bed \
--diff_map_regions chr1_GRCh38_alllowmapandsegdupregions.bed \
--functional_regions chr1_GRCh38_refseq_cds.bed \
-with-trace