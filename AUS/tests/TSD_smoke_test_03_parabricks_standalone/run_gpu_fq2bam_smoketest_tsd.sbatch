#!/bin/bash
#-------------------------------------------------------------------
# TSD deployability smoke test #4 -- runs a single real Parabricks GPU
# tool (`pbrun fq2bam`) against real FASTQ data via Singularity/Apptainer,
# no Nextflow involved. Standalone SLURM job, same as
# tests/gpu_diag_smoketest/run_gpu_diag_smoketest_tsd.sbatch.
#
# Where this sits in the test sequence:
#   1. hello_world.nf            -- Nextflow + SLURM + account plumbing
#   2. cpu_container_smoketest.nf -- CPU tools + container engine
#   3. gpu_diag_smoketest         -- GPU allocation/driver/--nv/env-var
#        diagnostics, ending with `pbrun --version` (no real workload)
#   4. THIS SCRIPT                -- a real pbrun GPU workload
#        (alignment/sorting/dup-marking) against real data, still without
#        Nextflow, isolating whether Parabricks itself -- not the
#        pipeline around it -- works end-to-end on TSD.
#
# Note:
#   - `pbrun fq2bam` needs BWA-indexed reference, - `Homo_sapiens*.fasta`
#     must have `.fai`, `.dict`, and the BWA index files (`.amb`, `.ann`,
#     `.bwt`, `.pac`, `.sa`) sitting alongside `--ref`, provided that 
#     location is bind-mounted below). Missing index files fail inside 
#     pbrun with an index-file error, not a TSD/container problem.
#
#   - This script only binds $WORK_DIR, $TMP_DIR, and /tsd/p11. If your
#     FASTQs/reference live somewhere else on TSD (e.g. under
#     /cluster/p/p11/... like the Nextflow pipelines' test data), either
#     copy them into $WORK_DIR first or add an extra `-B` for that path.
#
# Usage: from this directory, with sample_tumor_1.fastq.gz,
# sample_tumor_2.fastq.gz, and the indexed Homo_sapiens_assembly38.fasta
# already present here (see the doc's "Before your first run"):
#   sbatch run_gpu_fq2bam_smoketest_tsd.sbatch
#-------------------------------------------------------------------
#SBATCH -J gpu_fq2bam_smoketest
#SBATCH --account=p11
#SBATCH --partition=accel
#SBATCH --gpus=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=8000M
#SBATCH -t 00:20:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o errexit
set -o nounset
set -o pipefail

# --- Configuration Paths ---
CONTAINER="/tsd/p11/home/p11-pubuduss/parabricks-aus/clara-parabricks_4.7.1-1.sif"
WORK_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
TMP_DIR="${WORK_DIR}/pbrun_tmp"

cd "$WORK_DIR"
mkdir -p "$TMP_DIR"

# --- Environment Pass-Through for Slurm GPU Binding ---
export SINGULARITYENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"
export APPTAINERENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"

echo "Running on host: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Assigned GPU: ${CUDA_VISIBLE_DEVICES:-<unset>}"
echo "Container: $CONTAINER"
echo "Starting Parabricks fq2bam..."

# --- Execute via Singularity ---
singularity exec \
    --nv \
    --no-home \
    --pid \
    -B /tsd/p11 \
    -B "$WORK_DIR" \
    -B "$TMP_DIR" \
    "$CONTAINER" \
    --pwd "$WORK_DIR" \
    pbrun fq2bam \
        --ref Homo_sapiens_assembly38.fasta \
        --in-fq sample_tumor_1.fastq.gz sample_tumor_2.fastq.gz \
        --out-bam TUMOR01.bam \
        --read-group-sm TUMOR01 \
        --num-gpus 1 \
        --tmp-dir "$TMP_DIR"

echo "fq2bam completed successfully."
