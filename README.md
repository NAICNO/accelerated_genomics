# NAIC Accelerated Genomics

## Overview

NAIC Accelerated Genomics is a scalable and reproducible suite of GPU-enabled Next Generation Sequencing (NGS) analysis workflows/pipelines. It is implemented using the `Clara Parabricks` software, which is developed by NVIDIA. The main purpose of this suite is to accelerate NGS analysis using GPU platforms. This documentation provides a user guide for installing and using NAIC Accelerated Genomics suite.

## Project Organization

    ├── LICENSE
    ├── README.md               <- The top-level README for developers using this project
    ├── data                    <- Data directory
    │   ├── external_testdata   <- Testdata from third-party sources
    │   ├── internal_testdata   <- Intermediate Testdata 
    │   ├── processed           <- The final, canonical data sets for modeling
    │
    ├── tools                   <- Bioinformatics tools used in NVIDIA Parabricks
    │
    ├── references              <- User guide, manuals, and all other explanatory materials
    ├── workflows               <- Collection of scalable and reproducible workflows/pipelines that automate complex NGS rawdata processing tasks 
    |
    ├── notebooks               <- Jupyter notebooks with detailed analysis
    |
    |     *NOTE:  NOT YET IMPLEMENTED*
    |
    ├── reports                 <- *NOTE:  NOT YET IMPLEMENTED (Generated analysis as HTML, PDF, LaTeX, etc.)*
    │   └── figures             <- *Generated graphics and figures to be used in reporting*

--------

## User guide

`NAIC Accelerated Genomics` is a suite of complex NGS analysis pipelines that can be used to process and analyze NGS data. The suite provides GPU-based NGS pipelines for accelerated analysis, as well as CPU-based pipelines for benchmarking and quality control (QC) purposes. The following pipelines are available in the suite:

1. Accelerated germline pipeline: This pipeline is GPU-based and leverages the power of GPUs for fast and efficient analysis of NGS data.
2. CPU-based germline pipeline: This pipeline is CPU-based and can be used for benchmarking and comparison purposes.
3. Raw data quality control pipeline (QC pipeline): This pipeline performs quality control tests on raw NGS data, ensuring data integrity and accuracy.
4. Pipeline to evaluate results: This pipeline is used to evaluate and compare the results obtained from the GPU-based and CPU-based NGS pipelines.

### Installation

* NAIC Accelerated Genomics GitHub ripository
    `git clone git@github.com:NAICNO/accelerated_genomics.git`

* NGS analysis workflows are available in `accelerated_genomics/workflows`
 
* For detailed instructions on how to use the different pipelines in the NAIC Accelerated Genomics suite, please refer to the respective pipeline documentation provided in `Implementation details` section.

### Dependancies

NAIC Accelerated Genomics has the following dependencies that need to be installed before running the pipelines:

* [NextFlow](https://www.nextflow.io/) is used to manage the NAIC Accelerated Genomics pipelines/workflows. It needs to be installed before running the pipelines. To install NextFlow, run the following command:

  > ```
  > wget -qO- https://get.nextflow.io | bash
  > ```

* Java: NextFlow recommends Java version 11 up to 20 for executing and managing tasks. Please ensure that you have one of these Java versions installed. Note that the NGS analysis processes use the Java version available in the corresponding containers.

* Docker and/or Singularity: NAIC Accelerated Genomics ensures reproducibility through self-contained process execution and strict software version control. Docker or Singularity can be used for this purpose. The [tools page](tools/README.md) provides information on the Docker and Singularity images used in the pipelines. Please note that if you are running the pipelines via Singularity, you need to update the correct path to the directory containing Singularity images in the conf/singularity.conf and conf/slurm.conf files. Set the singularityDir variable to the path of the directory containing the Singularity images.

* Docker or Singularity
  * Ensures reproducibility through self-contained process execution and strict software version control
  * [Containers section in tools page](tools/Containers.md) provides information on docker and singularity images used in `NAIC Accelerated Genomics` pipelines
  * Note: Update the correct path to directory containing singularity images when pipelines are run via singularity
    * `def singularityDir = '<path to directory containg singularity images>' // conf/singularity.conf & conf/slurm.conf`

### System requirements for Accelerated NGS pipeline

Software and hardware requirements necessary to deploy Accelerated NGS pipeline, as outlined in the [Parabricks.v4.0.0 guide](https://docs.nvidia.com/clara/parabricks/4.0.0/gettingstarted.html#installation-requirements):

Minimum System Specifications per GPU Configuration

* For a 2 GPU configuration:
  * At least 100GB of CPU RAM.
  * A minimum of 24 CPU threads.
* For a 4 GPU configuration:
  * At least 196GB of CPU RAM.
  * A minimum of 32 CPU threads.
* For an 8 GPU configuration:
  * At least 392GB of CPU RAM.
  * A minimum of 48 CPU threads

Software Requirements

* NVIDIA driver version must be 465.32 or higher

### Reference Data

For various analyses, the NGS pipelines utilize specific reference datasets. Detailed information is available in the [references readme page](references) of the documentation.

### Implementation and Execution Details

The following pipelines can be executed using a set of NextFlow commands:

1. Accelerated germline pipeline
2. CPU-based germline pipeline
3. Raw data quality control pipeline (QC pipeline)
4. Pipeline to evaluate results

These pipelines can be run employing different execution platforms, which are selectable via NextFlow command line parameters:

* `--profile singularity`: for executing with the Singularity platform
* `--profile docker`: for running on Docker platform.
* `--profile slurm`: for utilization with the SLURM executor

### Accelerated germline pipeline (GPU pipeline)

To conduct germline sequence analysis using GPUs, execute the following command:

    bash nextflow-23.04.4-all \
    run \
    germline_pipeline.nf \
    -profile <PROFILE> \
    --fastq_folder <"path to the directory with raw sequence data"> \
    --genome_folder <"path to the directory with reference data"> \
    --genome_json <JSON listing reference files> \
    --processor GPU \
    --target_regions <"path to the target region file"> \
    -with-report \
    -with-trace \
    -resume

#### Additional Resources: Accelerated germline pipeline (GPU pipeline)

For a comprehensive overview, refer to the [Germline pipeline page](tools/Germline_pipeline), which includes a workflow diagram and description of processes.
For details on NVIDIA's Clara Parabricks, consult the [Parabricks readme page](tools/Parabricks.md).

### CPU germline-pipeline

To initiate the CPU-based germline sequence analysis, use the command below with the` --processor CPU` parameter:

    bash nextflow-23.04.4-all \
    run \
    germline_pipeline.nf \
    -profile <PROFILE> \
    --fastq_folder <"path to the directory with raw sequence data"> \
    --genome_folder <"path to the directory with reference data"> \
    --genome_json <JSON listing reference files> \
    --processor CPU \
    --target_regions <"path to the target region file"> \
    -with-report \
    -with-trace \
    -resume
  
####  Additional Resources: CPU germline-pipeline

* Detailed documentation, including a workflow chart, is available on the [Germline pipeline page](tools/Germline_pipeline)

### QC-pipeline

Perform quality control assessments on NGS data using the following command:

    bash nextflow-23.04.4-all run qc_cpu.nf \
    -profile <PROFILE> \
    --fastq_folder <"path to the directory with raw sequence data"> \
    --sample_name <name of the sample> \
    --target_regions <"path to the target region file"> \
    --bam_path <"path to the alignment file - BAM file"> \
    --bai_path <"path to the alignment-index file - BAI file"> \
    --genome_folder <"path to the directory with reference data"> \
    --genome_json <JSON listing reference files> \
    -with-report \
    -with-trace \
    -resume

####  Additional Resources: QC-pipeline

* [QC pipeline page](tools/QC.md) provides a detail description of `QC pipeline` with workflow chart and included processes.

### Results evaluation pipeline

To evaluate outcomes from both GPU and CPU germline pipelines, execute the following:

    ./nextflow run vc_eval.nf \
    -profile <PROFILE> \
    --sample_name NA12878_35x \
    --VC_GPU <VCF from GPU pipeline> \
    --VC_CPU <VCF from CPU pipeline> \
    --genome_folder <REFERENCE> \
    --genome_json reference_data.json \
    --target_regions <TARGET REGIONS> \
    --diff_map_regions <DIFFICULT TO MAP REGIONS provided by precisionFDA> \
    --functional_regions <FUNCTIONAL REGIONS provided by precisionFDA> \
    -with-trace

#### Additional Resources: Results evaluation pipeline

* Refer to the Results [Evaluation Pipeline Document](VC_evaluation.md) for a detailed description, including workflow charts and involved processes.