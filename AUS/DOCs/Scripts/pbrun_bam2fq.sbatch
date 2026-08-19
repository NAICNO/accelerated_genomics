#!/bin/bash
#-------------------------------------------------------------------
# pbrun bam2fq -- extract FASTQ file(s) from a BAM via NVIDIA Clara
# Parabricks. Standalone SLURM job (not Nextflow) for testing on Fox
# (Educloud Research, non-sensitive data).
#
# v2: stages inputs onto Fox's job-scratch area ($SCRATCH) and copies
# outputs back to the submit directory with `cleanup`, per Fox's own
# job-script documentation:
#   cp inputfiles $SCRATCH; cd $SCRATCH; ...; savefile outputfile1 outputfile2
# (https://documentation.sigma2.no/jobs/scratchfiles.html documents the
# same $SCRATCH/savefile/cleanup mechanism Fox reuses.)
#
# v1 bound $(pwd) straight into the container (`-B $(pwd):/workdir`) and
# relied on that being the same, persistent path on both the submit node
# and the GPU compute node -- the job completed (exit 0) but the FASTQ
# outputs never showed up back in the submit directory. Anchoring
# explicitly to $SCRATCH (a real, job-specific directory Slurm sets up)
# and copying back to $SLURM_SUBMIT_DIR (Slurm's own env var for "the
# directory sbatch was run from", more reliable than a bare $(pwd) once
# containers/mount namespaces are involved) avoids that ambiguity.
#
# Cluster/account/GPU settings match configs/PARABRICKS_FOX.conf
# (account=ec232, partition=accel, --gpus=1, --nv) so this behaves like
# a gpu_process step in the Nextflow pipelines.
#
# Usage: edit REFERENCE_FILE / INPUT_BAM / OUT_PREFIX / INPUT_DIR /
# CONTAINER below, then from the directory holding INPUT_DIR:
#   sbatch bam2fq.sbatch
#-------------------------------------------------------------------
#SBATCH --job-name=bam2fq_normal
#SBATCH --account=ec232
#SBATCH --partition=accel
#SBATCH --gpus=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o errexit
set -o nounset
set -o pipefail

# Uncomment/adjust if Fox requires an explicit module load for
# Singularity on compute nodes -- confirm against current Fox docs
# (see the "BEFORE FIRST RUN" note in configs/PARABRICKS_FOX.conf).
# module purge
# module load Singularity/x.y.z

# ---- inputs: filenames only, all expected under INPUT_DIR (relative to
#      the submit directory) ----
REFERENCE_FILE="GCA_000001405.15_GRCh38_no_alt_analysis_set.fa"
INPUT_BAM="tumor.bam"
OUT_PREFIX="sample_tumor"
INPUT_DIR="mutect_sample"

# ---- container: the real path you're already using on Fox ----
CONTAINER=/projects/ec232/ngs/ngs_singularity/clara-parabricks_4.3.0.1.sif

# $SLURM_SUBMIT_DIR is Slurm's own record of "the directory sbatch was
# run from" -- more reliable than $(pwd) once the job is running inside
# a container/private mount namespace on the compute node.
SUBMIT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# ---- stage inputs onto $SCRATCH (Slurm auto-provisions this per job on
#      Fox's shared parallel filesystem, and cleans it up after the job
#      ends) ----
cp "${SUBMIT_DIR}/${INPUT_DIR}/${REFERENCE_FILE}" "${SCRATCH}/"
cp "${SUBMIT_DIR}/${INPUT_DIR}/${INPUT_BAM}"       "${SCRATCH}/"
# bring the BAM index along too, if you have one on disk (bam2fq itself
# doesn't require it, but keeps this pattern reusable for later pbrun
# steps that do)
[[ -f "${SUBMIT_DIR}/${INPUT_DIR}/${INPUT_BAM}.bai" ]] && \
    cp "${SUBMIT_DIR}/${INPUT_DIR}/${INPUT_BAM}.bai" "${SCRATCH}/"

cd "${SCRATCH}"

# ---- register the copy-back BEFORE running pbrun, so it still fires if
#      the job errors out partway through (per Fox's savefile/cleanup
#      docs). Quoted so the `*` glob is expanded when cleanup actually
#      runs (after the FASTQs exist), not right now. ----
mkdir -p "${SUBMIT_DIR}/${INPUT_DIR}/fastq"
cleanup cp "${SCRATCH}/${OUT_PREFIX}"'*' "${SUBMIT_DIR}/${INPUT_DIR}/fastq/"

singularity exec --nv \
    -B "${SCRATCH}" \
    --pwd "${SCRATCH}" \
    "${CONTAINER}" \
    pbrun bam2fq \
    --ref        "${REFERENCE_FILE}" \
    --in-bam     "${INPUT_BAM}" \
    --out-prefix "${OUT_PREFIX}"
