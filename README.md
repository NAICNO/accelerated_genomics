# NAIC Clara Parabricks

`Clara Parabricks` is the NVIDIA software suite developed to analyze Next Generation Sequence (NGS) data using GPUs. `NAIC Clara Parabricks` is the Norwegian AI cloud implementation of the scalable and reproducible GPU-enabled NGS analysis workflows/pipelines using `Clara Parabricks` software suite.

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
    ├── docs                    <- *A default Sphinx project; see sphinx-doc.org*
    |
    ├── reports                 <- *NOTE:  NOT YET IMPLEMENTED (Generated analysis as HTML, PDF, LaTeX, etc.)*
    │   └── figures             <- *Generated graphics and figures to be used in reporting*

--------

## User guide

`NAIC Clara Parabricks` implements NGS analysis pipelines using the NextFlow scientific workflow manager. It enables users to submit a single NextFlow job that schedules, submits and tracks the various processes involved in a complex NGS analysis pipeline.

### Installation

    # Clone NAIC Clara Parabricks GitHub ripository
    git clone git@github.com:NAICNO/clara_parabricks.git

    # NGS analysis workflows are available in `clara_parabricks/workflows`
    cd clara_parabricks/workflows

### Implementation

#### Dependancies

`NAIC Clara Parabricks` requires the following dependencies to properly function:

* Docker or Singularity: Ensures reproducibility through self-contained process execution and strict software version control
* Java vxxx: Required by NextFlow to execute and manage tasks. Users should note that the NGS analysis processes use the Java version available in the corresponding container.

#### Reference data

NGS analysis pipelines require various reference datasets for different processes. Users should access the [references](references) section for more information.

#### Docker or singularity containers

* Docker images released by NVIDIA
    `nvcr.io/nvidia/clara/clara-parabricks:<TAG>`
* Convert docker images to singularity
    `singularity build clara-parabricks_<tag>.sif
    docker://nvcr.io/nvidia/clara/clara-parabricks:<tag>`

#### NextFlow job submission process

`NAIC Clara Parabricks` currently provides a germline sequencing data analysis pipeline. In order to submit the pipeline, users need to update the following configuration files accordingly.

**Configure `singularity config file`:**

Update `singularityDir` with the path to the directory containg singularity images

    # conf/singularity.conf
    def singularityDir = '<path to directory containg singularity images>'

**Run germline-pipeline:**

Users can submit germline sequence analysis pipeline using the following command.

    bash nextflow-23.04.4-all \
    run \
    germline_pipeline.nf \
    -profile singularity \
    --fastq_folder <"path to the directory with raw sequence data"> \
    --genome_folder <"path to the directory with reference data"> \
    --genome_json parabricks_testref.json \
    --processor GPU \
    --target_regions <"path to the target region file"> \
    -with-report \
    -with-trace \
    -resume
