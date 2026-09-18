#!/bin/sh
#
# `pbrun giraffe` Expected GBZ.v1 but got v2. To fix, 
# this script constructs the initial GBZ using v1 serialization format
# via vg gbwt with the flag --gbz-format 1, and then feeds that v1 GBZ
# to vg autoindex -G as specified in NVIDIA's manual
#-------------------------------------------------------------------
#SBATCH -J giraffe_refdata
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH -t 00:30:00

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

echo -e "\n=== 1. Build GBZ v1 directly from FASTA ==="
# NVIDIA Clara Parabricks expects GBZ version 1. Newer vg defaults to v2.
# We build a plain graph, parse reference haplotypes, and force v1 GBZ output.
RAW_GBZ="${OUTPUT_DIR}/${REF_BASE}.v1.gbz"

singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg construct -r "${REF_FASTA}" -t 12 > "${OUTPUT_DIR}/tmp/temp_graph.vg"

singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg gbwt \
    -p \
    -E \
    -o "${RAW_GBZ}" \
    --gbz-version 1 \
    -x "${OUTPUT_DIR}/tmp/temp_graph.vg"

##  -E / --parse-paths: Instructs vg to extract reference or
###     haplotype paths already embedded inside your graph file.
## -x: Tells vg gbwt that this specific file is the reference graph
##      containing the metadata it needs to load into the GBWT structure

rm -f "${OUTPUT_DIR}/tmp/temp_graph.vg"

# singularity exec -B "$(pwd)" "${VG_CONTAINER}" bash -c "
#     vg construct -r '${REF_FASTA}' -t '${SLURM_CPUS_PER_TASK:-4}' > '${OUTPUT_DIR}/tmp/temp_graph.vg'
#     vg gbwt -v 2 -E -o '${RAW_GBZ}' --gbz-format 1 -g '${OUTPUT_DIR}/tmp/temp_graph.vg'
#     rm -f '${OUTPUT_DIR}/tmp/temp_graph.vg'
# "

echo -e "\n=== 2. Generate Giraffe indexes from GBZ (-G) ==="
# Determine whether to use 'sr-giraffe' or 'giraffe' based on container version
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

# Pass the v1 GBZ via -G so vg autoindex preserves the format
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg autoindex \
        --workflow "${WORKFLOW}" \
        -G "${RAW_GBZ}" \
        --prefix "${OUTPUT_DIR}/${REF_BASE}" \
        --tmp-dir "${OUTPUT_DIR}/tmp" \
        --threads "${SLURM_CPUS_PER_TASK:-4}"

echo -e "\n=== 3. Discover and Validate Created Indexes ==="
GBZ_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.gbz' | grep -v 'v1.gbz' | head -n1 || true)"
# If autoindex did not output a separate .giraffe.gbz, fallback to the input RAW_GBZ
GBZ_FILE="${GBZ_FILE:-${RAW_GBZ}}"

DIST_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.dist' | head -n1)"
MIN_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.min' | head -n1)"
ZIP_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.zipcodes' | head -n1)"

# Fallback: build .zipcodes if workflow didn't create it
if [[ -z "${ZIP_FILE}" && -n "${GBZ_FILE}" && -n "${DIST_FILE}" ]]; then
    echo "Building .zipcodes index using vg zipcodes..."
    ZIP_FILE="${OUTPUT_DIR}/${REF_BASE}.zipcodes"
    singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
        vg zipcodes \
            -g "${GBZ_FILE}" \
            -d "${DIST_FILE}" \
            -t "${SLURM_CPUS_PER_TASK:-4}" > "${ZIP_FILE}"
fi

echo "GBZ:      ${GBZ_FILE}"
echo "DIST:     ${DIST_FILE:-<not found>}"
echo "MIN:      ${MIN_FILE:-<not found>}"
echo "ZIPCODES: ${ZIP_FILE:-<not found>}"

if [[ -z "${GBZ_FILE}" || -z "${DIST_FILE}" || -z "${MIN_FILE}" || -z "${ZIP_FILE}" ]]; then
    echo "ERROR: Missing one or more required indices (.gbz, .dist, .min, .zipcodes)." >&2
    exit 1
fi

echo -e "\n=== 4. Reference-paths list for pbrun giraffe ==="
REF_PATHS_FILE="${OUTPUT_DIR}/${REF_BASE}.paths.sub"

singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths -x "${GBZ_FILE}" -L > "${OUTPUT_DIR}/${REF_BASE}.paths.all"

# Filter out unlocalized, decoy, mitochondrial, and non-canonical contigs
grep -v '_decoy' "${OUTPUT_DIR}/${REF_BASE}.paths.all" \
    | grep -v '_random' \
    | grep -v 'chrUn_' \
    | grep -v 'chrEBV' \
    | grep -v 'chrM' \
    | grep -v 'chain_' > "${REF_PATHS_FILE}" || cp "${OUTPUT_DIR}/${REF_BASE}.paths.all" "${REF_PATHS_FILE}"

cat "${REF_PATHS_FILE}"

echo -e "\n=== 5. Graph-derived reference FASTA ==="
GRAPH_REF_FASTA="${OUTPUT_DIR}/${REF_BASE}.fasta.ref.fa"
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths --extract-fasta -x "${GBZ_FILE}" > "${GRAPH_REF_FASTA}"

module purge
module load "${SAMTOOLS_MODULE}"
samtools faidx "${GRAPH_REF_FASTA}"
samtools dict "${GRAPH_REF_FASTA}" > "${GRAPH_REF_FASTA%.fa}.dict"
