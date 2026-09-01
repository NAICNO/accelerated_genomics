# TSD Smoke Test 04: Standalone Parabricks GPU workload

## GPU-accelerated alignment, sorting, and duplicate marking (`run_gpu_fq2bam_smoketest_tsd.sbatch`)

This standalone SLURM smoke test runs a real Parabricks GPU workload, `pbrun fq2bam`, against paired FASTQ data through Singularity/Apptainer on TSD.

It verifies that Parabricks can use an allocated GPU to perform alignment, sorting, and duplicate marking end to end, independently of Nextflow. It follows the diagnostic-only GPU test and precedes GPU-enabled workflow testing.

It is the fourth deployment check in the TSD test sequence:

1. `hello_world.nf`: Nextflow, SLURM, and account plumbing.
2. `cpu_container_smoketest.nf`: CPU processes and Apptainer/Singularity containers.
3. `run_gpu_diag_smoketest_tsd.sbatch`: GPU allocation, container GPU visibility, and Parabricks runtime diagnostics.
4. `run_gpu_fq2bam_smoketest_tsd.sbatch`: standalone Parabricks GPU workload.

## What this test validates

- SLURM can allocate one GPU from the `accel` partition for a real workload.
- Singularity/Apptainer exposes the allocated GPU to Parabricks through `--nv`.
- GPU visibility is passed through with `SINGULARITYENV_CUDA_VISIBLE_DEVICES` and `APPTAINERENV_CUDA_VISIBLE_DEVICES`.
- The Parabricks container can access the staged FASTQ files and BWA-indexed reference.
- `pbrun fq2bam` completes GPU-accelerated alignment, sorting, and duplicate marking.
- The requested output BAM is produced successfully.

This test intentionally does **not** validate Nextflow orchestration or a complete somatic/germline workflow.

## Files

- `run_gpu_fq2bam_smoketest_tsd.sbatch`: standalone SLURM job that runs `pbrun fq2bam` inside the configured Parabricks container.

## Prerequisites

1. Access to TSD/Colossus with permission to use the `accel` GPU partition.
2. Update the SLURM account in `run_gpu_fq2bam_smoketest_tsd.sbatch` if `p11` is not your project account.
3. Confirm `CONTAINER` points to an accessible Parabricks `.sif` image.
4. Place these files in the directory from which `sbatch` is run, or adjust paths and bind mounts in the script:
   - `sample_tumor_1.fastq.gz`
   - `sample_tumor_2.fastq.gz`
   - `Homo_sapiens_assembly38.fasta`
5. Ensure the reference FASTA has its required companion files in the same accessible location:
   - `.fai`
   - `.dict`
   - BWA index files: `.amb`, `.ann`, `.bwt`, `.pac`, and `.sa`
6. Ensure Singularity is available on TSD GPU compute nodes.

## Run option

### Test 04: submit standalone Parabricks `fq2bam`

From the directory containing the script, FASTQs, and indexed reference:

```bash
sbatch run_gpu_fq2bam_smoketest_tsd.sbatch
```

Monitor the job:

```bash
squeue -u "$USER"
```

After completion, inspect the SLURM logs:

```bash
cat gpu_fq2bam_smoketest-<jobid>.out
cat gpu_fq2bam_smoketest-<jobid>.err
```

## Expected result

A successful job reports the host, job ID, assigned GPU, configured container, and the message:

```text
fq2bam completed successfully.
```

You should also see:

- Output BAM: `TUMOR01.bam`
- Temporary Parabricks work directory: `pbrun_tmp/`
- SLURM output and error logs: `gpu_fq2bam_smoketest-<jobid>.out` and `gpu_fq2bam_smoketest-<jobid>.err`

In a pass scenario, the job completes successfully without missing-reference-index, container mount/access, GPU visibility, or Parabricks execution errors.

## Troubleshooting scope

If this test fails, likely causes are GPU allocation, container accessibility, Singularity `--nv` support, CUDA device propagation, missing FASTQs, missing reference/BWA index files, or insufficient bind mounts. A successful test confirms the standalone Parabricks GPU runtime; failures are separate from Nextflow workflow orchestration.
