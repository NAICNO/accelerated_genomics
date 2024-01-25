# NAIC Accelerated Genomics

`NAIC Accelerated Genomics` is a scalable and reproducible GPU-enabled NGS analysis workflows/pipelines implemented using `Clara Parabricks` software suite. This pipeline is developed and maintained by the Norwegian AI cloud (NAIC). `Clara Parabricks` is the NVIDIA software suite developed to analyze Next Generation Sequence (NGS) data using GPUs.

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

`NAIC Accelerated Genomics` is a suite of complex NGS analysis pipelines. The main purpose of this suite is to accelerate NGS analysis using GPU platforms. Additionally, the suite provide set of CPU-based NGS pipelines that can be used to run benchmark and quality control (QC) tests on GPU-based workflows. The list of pipelines made available by the suite are

1. Accelerated NGS pipeline (GPU-based NGS pipeline)
2. CPU-based NGS pipeline
3. Raw data quality control pipeline (QC pipeline)
4. Pipeline to evaluate results from GPU- and CPU-based NGS pipelines

### Installation

    # Clone NAIC Accelerated Genomics GitHub ripository
    git clone git@github.com:NAICNO/accelerated_genomics.git

    # NGS analysis workflows are available in `accelerated_genomics/workflows`
    cd accelerated_genomics/workflows

### Dependancies

* NextFlow
  * [NextFlow](https://www.nextflow.io/) is used to manage `NAIC Accelerated Genomics` pipelines/workflows. Therefore uses NextFlow needs to be installed before running the pipelines.

> ```
> wget -qO- https://get.nextflow.io | bash
> ```

* Java
  * Java version 11 up to 20 are recommended by NextFlow to execute and manage tasks. Users should note that the NGS analysis processes use the Java version available in corresponding containers.

* Docker or Singularity
  * Ensures reproducibility through self-contained process execution and strict software version control
  * [tools page](tools/README_Parabricks.md) provides information on docker and singularity images used in `NAIC Accelerated Genomics` pipelines
  * Note: Update the correct path to directory containing singularity images when pipelines are run via singularity
    * `def singularityDir = '<path to directory containg singularity images>' // conf/singularity.conf & conf/slurm.conf`

### Reference data

NGS analysis pipelines require various reference datasets for different processes. Users should access the [references](references) section for more information.

### Implementation details

`NAIC Accelerated Genomics` currently provides a germline sequencing data analysis pipeline. In order to submit the pipeline, users need to update the following configuration files accordingly.

#### Run GPU germline-pipeline

Users can submit germline sequence analysis pipeline using the following command.

    bash nextflow-23.04.4-all \
    run \
    germline_pipeline.nf \
    -profile singularity \
    --fastq_folder <"path to the directory with raw sequence data"> \
    --genome_folder <"path to the directory with reference data"> \
    --genome_json <JSON listing reference files> \
    --processor GPU \
    --target_regions <"path to the target region file"> \
    -with-report \
    -with-trace \
    -resume

#### Processes in GPU germline-pipeline

* NVIDIA Parabricks -
  * `fq2bam`
  * `applybqsr`
  * `haplotypecaller`
  * `deepvariant`

Please refer documentation linked in [tools page](tools/README_Parabricks.md) for more details.

#### Run QC-pipeline

    bash nextflow-23.04.4-all run qc_cpu.nf \
    -profile singularity \
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
