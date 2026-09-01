#!/bin/bash
#-------------------------------------------------------------------
# gpu_diag -- diagnostic sweep of the TSD GPU/Singularity environment.
# Standalone SLURM job (not Nextflow). Prints, in order:
#   1. SLURM allocation info (node, job id, GPUs granted)
#   2. Host GPU hardware/driver (nvidia-smi on the bare compute node)
#   3. Mount permissions (checking for noexec on scratch/tmp areas)
#   4. Whether Singularity's --nv flag exposes the GPU inside the
#      container
#   5. Whether CUDA/NVIDIA env vars pass through into the container,
#      with and without an explicit SINGULARITYENV_ export
#   6. A real Parabricks runtime smoke test (`pbrun --version`)
#
# Fixed vs. the original draft:
#   - `$(hostname)` had a stray space breaking command substitution
#   - nvidia-smi --query-gpu values must be a single comma-separated
#     token with NO spaces (spaces made nvidia-smi see bogus extra args)
#   - `--format=csv` had a stray space after `--`
#   - line-continuation backslashes must be immediately followed by a
#     newline; a trailing space after `\` makes bash treat it as an
#     escaped literal space instead of a continuation, which silently
#     mangled the SINGULARITYENV_ commands in sections 5 and 6
#   - stray `!` and mount grep regex cleaned up
#
# Usage: edit CONTAINER below if your image path/version differs, then:
#   sbatch gpu_diag.sbatch
#-------------------------------------------------------------------
#SBATCH -J gpu_diag
#SBATCH -o gpu_diag_%j.out
#SBATCH --account=p11
#SBATCH --partition=accel
#SBATCH --gpus=1
#SBATCH --mem-per-cpu=8000M
#SBATCH -t 00:10:00

set -o nounset
set -o pipefail
# (not using errexit: this is a diagnostic script -- one failing probe,
# e.g. nvidia-smi not being on PATH, shouldn't abort the rest of the
# sections)

CONTAINER="/ess/p11/home/p11-pubuduss/parabricks-aus/clara-parabricks_v4.3.1-1.sig"

# Uncomment/adjust if TSD requires an explicit module load for
# Singularity on compute nodes -- confirm with `module avail singularity`
# module purge
# module load Singularity/x.y.z

echo "=== 1. SLURM ENVIRONMENT & ALLOCATION ==="
echo "Host Node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Allocated GPUs: ${SLURM_JOB_GPUS:-<unset>}"
echo "Host CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-<unset>}"
echo ""
scontrol show job "$SLURM_JOB_ID" | grep -E "NodeList|Gres|TRES"

echo -e "\n=== 2. HOST GPU HARDWARE & DRIVER ==="
nvidia-smi --query-gpu=index,name,compute_cap,driver_version,memory.total --format=csv

echo -e "\n=== 3. MOUNT PERMISSIONS (Checking for noexec) ==="
mount | grep -E "localscratch|projects01|tmp"

echo -e "\n=== 4. SINGULARITY GPU RECOGNITION (Standard --nv) ==="
singularity exec --nv "$CONTAINER" nvidia-smi --query-gpu=index,name,compute_cap --format=csv

echo -e "\n=== 5. SINGULARITY ENVIRONMENT PASS-THROUGH ==="
echo "Without explicit pass-through:"
singularity exec --nv "$CONTAINER" env | grep -E "CUDA|NVIDIA" || echo "No CUDA vars found"
echo -e "\nWith SINGULARITYENV pass-through:"
SINGULARITYENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}" \
    singularity exec --nv "$CONTAINER" env | grep -E "CUDA|NVIDIA"

echo -e "\n=== 6. PARABRICKS RUNTIME TEST ==="
SINGULARITYENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}" \
    singularity exec --nv "$CONTAINER" pbrun --version
