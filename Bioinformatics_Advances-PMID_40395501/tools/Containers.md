# Container Technologies: Docker and Singularity

NAIC Accelerated Genomics utilizes container technologies, including Docker and Singularity, to ensure reproducibility, portability, and adequate software version control. This document provides detailed guidance for managing Docker and Singularity images.

## Singularity images

* Singularity images are employed to execute pipelines in Virtual Machines (VMs) and High-Performance Computing (HPC) clusters.

* Singularity Image Definitions: Singularity images, along with their corresponding versions, are defined within the `accelerated_genomics/workflows/conf/singularity.conf` and `accelerated_genomics/workflows/conf/slurm.conf` files.

* Singularity Image Sources: Singularity images are built from official Docker images, released by the corresponding tool developer.

* Building Singularity Images: Build Singularity images with the singularity build command as shown below:

 > `singularity build <singularity_image_name>_<tag>.sig docker://<docker_image_name>:<tag>`

* Directory Path Configuration:
  * While running pipelines via Singularity, make sure to accurately update the directory path to the Singularity images within the `conf/singularity.conf` and `conf/slurm.conf` files. For this, set the `singularityDir` variable to the directory's path containing the Singularity images.

## Docker images

Docker Image Definitions: The Docker images, along with their corresponding versions, are listed in the `accelerated_genomics/workflows/conf/docker.conf` file.

* `NAIC Accelerated Genomics` uses docker images to run pipelines in virtual machines
* The list of docker images (tagged with corresponding versions) used are listed in `accelerated_genomics/workflows/conf/docker.conf`

### Container Images for GPU and CPU Pipelines

Image use differs based on whether the pipeline is GPU-accelerated or CPU-based.

### GPU Pipeline

The Parabricks Docker image is used in the GPU pipeline:

* Parabricks:`nvcr.io/nvidia/clara/clara-parabricks`
* Source: [Nvidia Clara Parabricks](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks/tags)

### CPU pipeline

Multiple Docker images are utilized in the CPU pipeline:

Source:

* BWA and SAMTools: `bwa_samtools_amd64:<tag> // Source: https://github.com/NAICNO/NAIC-Dockerfiles/blob/main/bwa-samtools/Dockerfile`
* DeepVariant: `google/deepvariant:<tag>`
* MosDepth: `quay.io/biocontainers/mosdepth:<tag>`
* FASTQC: `quay.io/biocontainers/fastqc:<tag>`
* MultiQC: `quay.io/biocontainers/multiqc:<tag>`
