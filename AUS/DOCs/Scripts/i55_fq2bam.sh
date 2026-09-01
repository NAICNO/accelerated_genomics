#!/bin/bash
#SBATCH -J pb_fq2bam
#SBATCH -o pb_fq2bam_%j.out
#SBATCH -e pb_fq2bam_%j. err
#SBATCH -p accel
#SBATCH --account=p11 --mem-per-cpu=8000M
#SBATCH --gpus=1
#SBATCH -c 8
#SBATCH -t 00:20:00
set -euo pipefail

# -- Configuration Paths ---
CONTAINER="/ess/p11/home/p11-pubuduss/parabricks-aus/clara-parabricks_v4.3.1-1.sig"
WORK_DIR="$ (pwd) "
TMP_DIR="${WORK_DIR}/pbrun_tmp"

mkdir -p "$TMP_DIR"

# --- Environment Pass-Through for Slurm GPU Binding ---
export SINGULARITYENV_CUDA_VISIBLE_DEVICES="ȘCUDA_VISIBLE_DEVICES" export APPTAINERENV_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES"
echo "Running on host: $ (hostname) " echo "Assigned GPU: $CUDA_VISIBLE_DEVICES" echo "Starting Parabricks fq2bam..."

# --- Execute via Singularity ---
singularity exec \
    --no-home \
    --pid \
    -B /ess/p11 \
    -B "$WORK_DIR" \
    -B "$TMP_DIR" \
    "$CONTAINER" \
    pbrun fq2bam \
        --ref Homo_sapiens_assembly38.fasta \
        --in-fq sample_normal_1. fastq-gz sample_normal_2.fastqgz V
        --out-bam TUMOR01. bam
        -- read-group-sm NORMAL01 \
        --num-gpus 1 \
        --tmp-dir "$TMP_DIR"

echo "fq2bam completed successfully."