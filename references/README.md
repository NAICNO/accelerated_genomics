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

* Access test dataset - follow instructions in [data/external_testdata folder](external_testdata/README.md)
* Run Parabricks singularity image created in the previous step

```bash
singularity exec \
    --nv \
    --cleanenv \
    --bind /host/data/parabricks_sample:/mnt \
    --bind /host/results:/outputdir \
    --pwd /outputdir \
    clra-aparabricks_v4.1.2-1.sif \
    pbrun fq2bam \
    --ref /mnt/Ref/Homo_sapiens_assembly38.fasta \
    --in-fq /mnt/Data/sample_1.fq.gz /mnt/Data/sample_1.fq.gz \
    --out-bam /outputdir/fq2bam_output.bam
```
