#!/bin/bash
#-------------------------------------------------------------------
# TSD GPU deployability smoke test #3 -- gpu_diag: diagnostic sweep of the
# TSD GPU/Singularity environment. Standalone SLURM job (not Nextflow).
#
# Where this sits in the test sequence:
#   1. hello_world.nf             -- Nextflow + SLURM + account plumbing
#   2. cpu_container_smoketest.nf -- CPU tools + container engine
#   3. THIS SCRIPT                -- GPU allocation/driver/--nv/env-var
#      diagnostics, ending with a real `pbrun --version` call inside the
#      container (no GPU compute workload yet -- that's smoke test #4).

# This test plays the same "isolate one layer
# of the stack before trusting the pipeline on top of it" role they do
# -- it just checks the GPU/container layer specifically, rather than
# Nextflow/SLURM or CPU containers.
#
# Prints, in order:
#   1. SLURM allocation info (node, job id, GPUs granted)
#   2. Host GPU hardware/driver (nvidia-smi on the bare compute node)
#   3. Mount permissions (checking for noexec on scratch/tmp areas)
#   4. Whether Singularity's --nv flag exposes the GPU inside the
#      container
#   5. Whether CUDA/NVIDIA env vars pass through into the container,
#      with and without an explicit SINGULARITYENV_ export
#   6. A real Parabricks runtime smoke test (`pbrun --version`)
#
#
# Usage: edit CONTAINER below if your image path/version differs, then,
# from this directory:
#   sbatch run_gpu_diag_smoketest_tsd.sbatch
#-------------------------------------------------------------------
#SBATCH -J gpu_diag_smoketest
#SBATCH --account=p11
#SBATCH --partition=accel
#SBATCH --gpus=1
#SBATCH --mem-per-cpu=8000M
#SBATCH -t 00:10:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o nounset
set -o pipefail
# (not using errexit: this is a diagnostic script -- one failing probe,
# e.g. nvidia-smi not being on PATH, shouldn't abort the rest of the
# sections)

CONTAINER="<path>/parabricks-aus/clara-parabricks_4.7.1-1.sif"

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
mount | grep -E "localscratch|projects01|ess|cluster|tsd|tmp"

echo -e "\n=== 3b. DIRECT ACCESS CHECK (CONTAINER path) ==="
# `mount` above is only a snapshot of what's already mounted in *this*
# job's mount namespace -- an autofs-style automount, or a path that's
# only mounted on the login node and not this GPU compute node, won't
# show up there even though it's genuinely reachable (or genuinely
# not). Directly touching the path is the more reliable check: it
# either triggers any automount and succeeds, or fails with a real
# error explaining why (No such file or directory, Permission denied,
# etc.) -- see the "Round 3" note in tsd-gpu-diag-smoke-test.md for why
# this was added.
echo "Listing $(dirname "$CONTAINER"):"
ls -la "$(dirname "$CONTAINER")" 2>&1 || echo "-> NOT accessible from this node"
echo ""
echo "Stat-ing CONTAINER itself:"
stat "$CONTAINER" 2>&1 || echo "-> NOT accessible from this node"

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
