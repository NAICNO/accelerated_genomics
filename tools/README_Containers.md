# Singularity and docker

* `NAIC Accelerated Genomics` uses container technology to ensures reproducibility, portablility and software version control.
* NextFlow configuration files define the singularity and docker images used for each process in the pipeline.

## Singularity images

* `NAIC Accelerated Genomics` uses singularity images to run pipelines in virtual machines and HPC clusters
* The list of singularity images (tagged with corresponding versions) used in the pipelines are defined in
  * `accelerated_genomics/workflows/conf/singularity.conf`
  * `accelerated_genomics/workflows/conf/slurm.conf`
* All singularity images are build from official docker image released by the developer of the corresponding tool
* Build docker image via `singularity build` command
  * `singularity build <singularity_image_name>_<tag>.sig docker://<docker_image_name>:<tag>`

## Docker images

* `NAIC Accelerated Genomics` uses docker images to run pipelines in virtual machines
* The list of docker images (tagged with corresponding versions) used are listed in `accelerated_genomics/workflows/conf/docker.conf`

## Images used in GPU and CPU pipelines

### GPU pipeline

* Parabricks: `nvcr.io/nvidia/clara/clara-parabricks // Source: https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks/tags`

### CPU pipeline

* BWA and SAMTools: `bwa_samtools_amd64:<tag> // Source: https://github.com/NAICNO/NAIC-Dockerfiles/blob/main/bwa-samtools/Dockerfile`
* DeepVariant: `google/deepvariant:<tag>`
* MosDepth: `quay.io/biocontainers/mosdepth:<tag>`
* FASTQC: `quay.io/biocontainers/fastqc:<tag>`
* MultiQC: `quay.io/biocontainers/multiqc:<tag>`
