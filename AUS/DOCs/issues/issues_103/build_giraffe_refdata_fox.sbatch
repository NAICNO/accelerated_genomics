#!/bin/bash
#-------------------------------------------------------------------
# build_giraffe_refdata_fox -- generate the pbrun giraffe reference
# bundle (.gbz/.dist/.min/.zipcodes + ref-paths list + graph-derived
# FASTA) from the vg "tiny" test dataset, on Fox. CPU-only (no GPU) --
# this builds graph indices with vg, it does not run pbrun giraffe
# itself. Standalone SLURM job, no Nextflow, same "bypass the pipeline
# to isolate one step" pattern as tests/gpu_fq2bam_smoketest.
#
# Produces the five inputs downstream steos need 
# (graph_gbz/graph_dist/graph_min/graph_zipcodes/graph_ref_paths),
# plus a graph-derived reference FASTA
#     (params.ref must come from the SAME graph used for alignment).
#
# Input: Homo_sapiens_assembly38.fasta (Parabricks test-reference FASTA)
#
# Output: 
# - `--workflow sr-giraffe` automatically generates the exact 
#             set needed for short-read mapping: hs38.giraffe.gbz, hs38.dist, hs38.min, and hs38.zipcodes.
# - `lr-giraffe` targets long-read alignment pipelines and generates a different combination of indexes 
#   (typically omitting the short-read minimizer/zipcode pair in favor of structures tailored for long-read seeds)
#
#
# Usage: place this script and the `tiny/` folder in the same
# directory, adjust VG_CONTAINER/ACCOUNT below, then:
#   sbatch build_giraffe_refdata_fox.sbatch
#
# Raised errors: read: https://github.com/NAICNO/accelerated_genomics/issues/103#issuecomment-5704137737
#-------------------------------------------------------------------
#SBATCH -J giraffe_refdata
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=4
#SBATCH --mem=256G
#SBATCH -t 01:00:00

set -o errexit
set -o nounset
set -o pipefail

# ---- Configuration ----
VG_CONTAINER="vg.sif"
SAMTOOLS_MODULE="SAMtools/1.17-GCC-12.2.0"
REF_DIR="tiny_ref"
REF_BASE="Homo_sapiens_assembly38"
REF_FASTA="${REF_DIR}/${REF_BASE}.fasta"
OUTPUT_DIR="${REF_DIR}"

mkdir -p "${OUTPUT_DIR}/tmp"

echo "=== 0. Sanity-check inputs ==="
if [[ ! -f "${REF_FASTA}" ]]; then
    echo "ERROR: Expected ${REF_FASTA} -- not found." >&2
    exit 1
fi
ls -la "${REF_DIR}"

echo -e "\n=== 1. vg autoindex -- build the giraffe index bundle ==="
AUTOINDEX_HELP="$(singularity exec "${VG_CONTAINER}" vg autoindex --help 2>&1 || true)"
if echo "${AUTOINDEX_HELP}" | grep -qw 'sr-giraffe'; then
    WORKFLOW="sr-giraffe"
elif echo "${AUTOINDEX_HELP}" | grep -qw 'giraffe'; then
    WORKFLOW="giraffe"
else
    echo "ERROR: neither 'giraffe' nor 'sr-giraffe' found in 'vg autoindex --help'." >&2
    exit 1
fi
echo "Using --workflow ${WORKFLOW}"

singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg autoindex \
        --workflow "${WORKFLOW}" \
        --ref-fasta "${REF_FASTA}" \
        --prefix "${OUTPUT_DIR}/${REF_BASE}" \
        --tmp-dir "${OUTPUT_DIR}/tmp" \
        --threads "${SLURM_CPUS_PER_TASK:-4}"

echo -e "\n=== 2. Discover and Validate Created Indexes ==="
GBZ_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.gbz' | head -n1)"
DIST_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.dist' | head -n1)"
MIN_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.min' | head -n1)"
ZIP_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.zipcodes' | head -n1)"

# Fallback: Build .zipcodes explicitly if workflow was 'giraffe' rather than 'sr-giraffe'
if [[ -z "${ZIP_FILE}" && -n "${GBZ_FILE}" && -n "${DIST_FILE}" ]]; then
    echo "Building missing .zipcodes index via 'vg zipcodes'..."
    ZIP_FILE="${OUTPUT_DIR}/${REF_BASE}.zipcodes"
    singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
        vg zipcodes \
            -g "${GBZ_FILE}" \
            -d "${DIST_FILE}" \
            -t "${SLURM_CPUS_PER_TASK:-4}" > "${ZIP_FILE}"
fi

echo "GBZ:      ${GBZ_FILE:-<not found>}"
echo "DIST:     ${DIST_FILE:-<not found>}"
echo "MIN:      ${MIN_FILE:-<not found>}"
echo "ZIPCODES: ${ZIP_FILE:-<not found>}"

if [[ -z "${GBZ_FILE}" || -z "${DIST_FILE}" || -z "${MIN_FILE}" || -z "${ZIP_FILE}" ]]; then
    echo "ERROR: Failed to generate all required indices (.gbz, .dist, .min, .zipcodes)." >&2
    exit 1
fi

echo -e "\n=== 3. Reference-paths list (--ref-paths input for pbrun giraffe) ==="
REF_PATHS_FILE="${OUTPUT_DIR}/${REF_BASE}.ref_paths.txt"
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths --list --xg "${GBZ_FILE}" > "${REF_PATHS_FILE}"
cat "${REF_PATHS_FILE}"

echo -e "\n=== 4. Graph-derived reference FASTA ==="
GRAPH_REF_FASTA="${OUTPUT_DIR}/${REF_BASE}.fasta.ref.fa"
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths --extract-fasta --xg "${GBZ_FILE}" > "${GRAPH_REF_FASTA}"

module purge
module load "${SAMTOOLS_MODULE}"
samtools faidx "${GRAPH_REF_FASTA}"
samtools dict "${GRAPH_REF_FASTA}" > "${GRAPH_REF_FASTA%.fa}.dict"
