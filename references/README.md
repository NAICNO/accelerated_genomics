# User guide

## Requirements

[*Software and hardware requirements were extracted from parabricks.v4.0.0 installation & requirements guide*](https://docs.nvidia.com/clara/parabricks/4.0.0/gettingstarted.html#installation-requirements)

* Hardware Requirements
  * NVIDIA GPU supporting CUDA architecture 60, 70, 75, or 80
  * Minimum RAM requirement = 16GB
* System Requirements
  * 2 GPU server should have at least 100GB CPU RAM and at least 24 CPU threads
  * A 4 GPU server should have at least 196GB CPU RAM and at least 32 CPU threads.
  * A 8 GPU server should have at least 392GB CPU RAM and at least 48 CPU threads.
* Software Requirements
  * NVIDIA driver version > 465.32

## Implementing Parabricks on UiO ML-Nodes

*Follow the [link](https://www.uio.no/tjenester/it/forskning/kompetansehuber/uio-ai-hub-node-project/it-resources/ml-nodes/) to learn more information on UiO ML-Nodes*

* NVIDIA provides a number of docker images to implement parabricks. In order to implement parabricks on UiO ML-nodes, docker images needs to be converted to singularity images.

```bash
singularity build clara-parabricks_v4.1.2-1.sif docker://nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1
```

## Run parabricks using singularity

* Access test dataset - `https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz`

```bash

wget -O parabricks_sample.tar.gz "https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz"

# Structure of the testdata directory
## parabricks_sample
## |-- Data
## |   |-- sample_1.fq.gz
## |   `-- sample_2.fq.gz
## `-- Ref
##     |-- Homo_sapiens_assembly38.dict
##     |-- Homo_sapiens_assembly38.fasta
##     |-- Homo_sapiens_assembly38.fasta.amb
##     |-- Homo_sapiens_assembly38.fasta.ann
##     |-- Homo_sapiens_assembly38.fasta.bwt
##     |-- Homo_sapiens_assembly38.fasta.fai
##     |-- Homo_sapiens_assembly38.fasta.pac
##     |-- Homo_sapiens_assembly38.fasta.sa
##     |-- Homo_sapiens_assembly38.known_indels.vcf.gz
##     `-- Homo_sapiens_assembly38.known_indels.vcf.gz.tbi

## Basic stats of the raw fastq files in `Data` direcory
### file               format  type    num_seqs        sum_len  min_len  avg_len  max_len
### sample_1.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
### sample_2.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
```

* Run Parabricks singularity image

```bash
singularity exec \
    --nv \  # Use this option if you want to use GPUs, equivalent to --gpus all in Docker
    --cleanenv \  # Optionally clean the environment (similar to --rm in Docker)
    --bind /host/data/parabricks_sample:/mnt \  # Map the host directory to the container
    --bind /host/results:/outputdir \  # Map the host directory to the container
    --pwd /outputdir \  # Set the working directory inside the container
    clra-aparabricks_v4.1.2-1.sif \
    pbrun fq2bam \
    --ref /mnt/Ref/Homo_sapiens_assembly38.fasta \
    --in-fq /mnt/Data/sample_1.fq.gz /mnt/Data/sample_1.fq.gz \
    --out-bam /outputdir/fq2bam_output.bam
```
