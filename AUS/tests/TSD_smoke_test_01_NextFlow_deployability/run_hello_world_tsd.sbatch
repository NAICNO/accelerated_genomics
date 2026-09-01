#!/bin/bash
#-------------------------------------------------------------------
# Runs hello_world.nf on TSD via SLURM.
#
# Usage: from this directory,
#   sbatch run_hello_world_tsd.sbatch
# then check progress with `squeue -u $USER` and read the logs named
# below once it finishes (or tail -f them while it runs).
#
# No input/reference-data staging step here (unlike bam2fq.sbatch's
# $SCRATCH copy-in/copy-out for Fox): hello_world.nf and hello_world.config
# are tiny script/config files, not data, and they already live on
# /cluster (TSD's shared parallel filesystem), which PARABRICKS_TSD.conf /
# TSD.config bind-mount (-B /cluster,/gpfs) precisely because it's visible
# from both the login node and the compute nodes. Nothing needs copying
# anywhere for the compute node to read these two files directly.
#-------------------------------------------------------------------
#SBATCH --job-name=hello_world_nf
#SBATCH --account=pXX
#SBATCH --mem-per-cpu=1000M
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o errexit
set -o nounset
set -o pipefail

# SLURM sets the job's initial working directory to wherever `sbatch`
# was run from, but pin it explicitly with SLURM's own env var rather
# than relying on that -- $SLURM_SUBMIT_DIR is more reliable than a bare
# $(pwd) once a job has actually started on a compute node (same
# reasoning as bam2fq.sbatch's SUBMIT_DIR variable).
cd "${SLURM_SUBMIT_DIR:-$(pwd)}"

module purge
module load Nextflow/24.04.0

nextflow run hello_world.nf -c hello_world.config -profile tsd
