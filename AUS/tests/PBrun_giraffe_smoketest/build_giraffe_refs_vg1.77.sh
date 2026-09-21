#!/bin/bash
# Build Giraffe reference data using VG v1.77 with GBZ v1 serialization format
# `pbrun giraffe` Expected GBZ.v1 but got v2. To fix, 
# this script constructs the initial GBZ using v1 serialization format
# via vg gbwt with the flag --gbz-format 1, and then feeds that v1 GBZ
# to vg autoindex -G as specified in NVIDIA's manual
#
#-------------------------------------------------------------------
#SBATCH -J giraffe_refdata
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=1
#SBATCH --mem=256G
#SBATCH -t 04:30:00

set -o errexit
set -o nounset
set -o pipefail

# ---- Configuration ----
VG_CONTAINER="vg_v1.77.0.sif"
SAMTOOLS_MODULE="SAMtools/1.17-GCC-12.2.0"
REF_DIR="tiny_ref"
REF_BASE="Homo_sapiens_assembly38"
REF_FASTA="${REF_DIR}/${REF_BASE}.fasta"
OUTPUT_DIR="${REF_DIR}"

# Set specific prefixes for output files
AUTOINDEX_PREFIX="${OUTPUT_DIR}/${REF_BASE}.autoindex.1.77"
GBZ_FILE="${AUTOINDEX_PREFIX}.giraffe.gbz"

echo "Starting Giraffe reference dataset generation..."

# 1. Generate the Required Index Files (.gbz, .dist, .min, .zipcodes)
echo "Running vg autoindex..."
singularity exec -B "${PWD}:${PWD}" -B "${TMPDIR}:${TMPDIR}" "${VG_CONTAINER}" vg autoindex \
    -p "${AUTOINDEX_PREFIX}" \
    -r "${REF_FASTA}" \
    -w giraffe

# 2. Extract Reference Paths from the GBZ Graph
echo "Extracting paths from GBZ..."
singularity exec -B "${PWD}:${PWD}" -B "${TMPDIR}:${TMPDIR}" "${VG_CONTAINER}" vg paths \
    -x "${GBZ_FILE}" \
    -L > "${OUTPUT_DIR}/${REF_BASE}.paths"

# 3. Clean up Non-Primary Paths
echo "Filtering out non-primary paths..."
grep -v _decoy "${OUTPUT_DIR}/${REF_BASE}.paths" \
    | grep -v _random \
    | grep -v chrUn_ \
    | grep -v chrEBV \
    | grep -v chrM \
    | grep -v chain_ > "${OUTPUT_DIR}/${REF_BASE}.paths.sub"

# 4. Extract FASTA for Downstream Variant Calling and Index with SAMtools
# Parabricks variant calling workflows require the FASTA extracted directly from the pangenome paths
echo "Extracting final FASTA from paths and generating SAMtools index..."
singularity exec -B "${PWD}:${PWD}" -B "${TMPDIR}:${TMPDIR}" "${VG_CONTAINER}" vg paths \
    -x "${GBZ_FILE}" \
    -p "${OUTPUT_DIR}/${REF_BASE}.paths.sub" \
    -F > "${OUTPUT_DIR}/${REF_BASE}.gbz.fa"

module purge
module load "${SAMTOOLS_MODULE}"
samtools faidx "${OUTPUT_DIR}/${REF_BASE}.gbz.fa"
samtools dict "${OUTPUT_DIR}/${REF_BASE}.gbz.fa" > "${OUTPUT_DIR}/${REF_BASE}.gbz.dict"

echo "Giraffe reference data generation completed successfully."