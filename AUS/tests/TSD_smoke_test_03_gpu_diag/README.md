# TSD Smoke Test 03: GPU diagnostics

## GPU allocation, Singularity GPU access, and Parabricks runtime (`run_gpu_diag_smoketest_tsd.sbatch`)

This standalone SLURM smoke test verifies that a TSD GPU compute node, Singularity GPU passthrough, and the Parabricks runtime are available before running GPU-enabled Nextflow workflows.

It is the third deployment check in the TSD test sequence:

1. `hello_world.nf`: Nextflow, SLURM, and account plumbing.
2. `cpu_container_smoketest.nf`: CPU processes and Apptainer/Singularity containers.
3. `run_gpu_diag_smoketest_tsd.sbatch`: GPU diagnostics and Parabricks container runtime.

## What this test validates

- SLURM can allocate one GPU from the `accel` partition.
- The compute node exposes GPU hardware and NVIDIA driver details through `nvidia-smi`.
- The configured container image is accessible from the allocated GPU node.
- Singularity's `--nv` option makes the allocated GPU visible inside the container.
- CUDA and NVIDIA environment variables are visible inside the container, including explicit `SINGULARITYENV_CUDA_VISIBLE_DEVICES` passthrough.
- The Parabricks executable starts successfully inside the container with `pbrun --version`.

This test intentionally does **not** run a GPU compute workload or validate an end-to-end GPU pipeline. Those belong to the next smoke test.

## Files

- `run_gpu_diag_smoketest_tsd.sbatch`: standalone SLURM diagnostic script. It performs all host, container, GPU, and Parabricks runtime checks.

## Prerequisites

1. Access to TSD/Colossus with permission to use the GPU partition.
2. Update the SLURM account in `run_gpu_diag_smoketest_tsd.sbatch`.
3. Update `CONTAINER` in the script to the accessible Parabricks `.sif` image path for your project.
4. Ensure Singularity is available on TSD GPU compute nodes. Load the appropriate module in the script if required by the environment.

## Run option

### Test 03: submit GPU diagnostics

From this directory:

```bash
sbatch run_gpu_diag_smoketest_tsd.sbatch
```

Monitor the job:

```bash
squeue -u "$USER"
```

After completion, inspect the SLURM logs:

```bash
cat gpu_diag_smoketest-<jobid>.out
cat gpu_diag_smoketest-<jobid>.err
```

## Expected result

A successful job prints six diagnostic sections in the `.out` log:

1. **SLURM environment and allocation:** hostname, job ID, and allocated GPU information.
2. **Host GPU hardware and driver:** `nvidia-smi` reports the available GPU model, compute capability, driver version, and memory.
3. **Mount permissions and direct access:** the configured container directory and image can be listed and stat-ed from the GPU node.
4. **Singularity GPU recognition:** `singularity exec --nv ... nvidia-smi` reports the GPU from inside the container.
5. **Singularity environment pass-through:** CUDA/NVIDIA variables are shown, including the explicit `SINGULARITYENV_CUDA_VISIBLE_DEVICES` case.
6. **Parabricks runtime test:** `pbrun --version` prints the version from inside the container.

The SLURM job should complete successfully, with no inaccessible-container, GPU-recognition, or Parabricks startup errors.

## Troubleshooting scope

If this test fails, likely causes are GPU allocation, NVIDIA driver visibility, Singularity `--nv` support, container-path accessibility, or CUDA environment propagation. A failure at this stage is separate from Nextflow workflow logic and GPU bioinformatics workload behavior.
