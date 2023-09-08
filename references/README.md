# User guide

## [Requirements](https://docs.nvidia.com/clara/parabricks/4.0.0/gettingstarted.html#installation-requirements)

* Hardware Requirements
  * NVIDIA GPU supporting CUDA architecture 60, 70, 75, or 80
  * Minimum RAM requirement = 16GB
* System Requirements
  * Follow the [source documentation](https://docs.nvidia.com/clara/parabricks/4.0.0/gettingstarted.html#installation-requirements) for detailed description of system Requirements
* Software Requirements
  * NVIDIA driver version > 465.32.*

## Implementing Parabricks on [UiO ML-Nodes](https://www.uio.no/tjenester/it/forskning/kompetansehuber/uio-ai-hub-node-project/it-resources/ml-nodes/)

* NVIDIA provides a number of docker images to implement parabricks. In order to implement parabricks on UiO ML-nodes, docker images needs to be converted to singularity images.

```bash
singularity build clara-parabricks_v4.1.2-1.sif docker://nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1
```
