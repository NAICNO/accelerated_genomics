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
# Expects an input directory (INPUT_DIR below) containing the files
# from `ls tiny/` you already downloaded -- at minimum tiny.gfa,
# tiny.fa, tiny.vcf.gz(.tbi). The .gam files in that set are pre-
# simulated read alignments, not FASTQ -- NOT converted by this script
# (see "Optional" section at the bottom; left as a manual/unconfirmed
# step, not run automatically).
#
#
# Usage: place this script and the `tiny/` folder in the same
# directory, adjust VG_CONTAINER/ACCOUNT below, then:
#   sbatch build_giraffe_refdata_fox.sbatch
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
# errexit is appropriate here (unlike gpu_diag.sbatch's diagnostic
# sweep): this is a deterministic build pipeline where a partial/
# corrupt index silently continuing would be worse than the job
# stopping -- same reasoning as gpu_fq2bam_smoketest.

# ---- adjust these ----
VG_CONTAINER="vg.sif"
ACCOUNT="ec232"                                           # matches configs/PARABRICKS_FOX.conf
SAMTOOLS_MODULE="SAMtools/1.17-GCC-12.2.0"                # adjust per `module avail samtools` on Fox

INPUT_DIR="tiny"
OUTPUT_DIR="refdata"
PREFIX="tiny_index"

mkdir -p "${OUTPUT_DIR}/tmp"
# `mkdir -p "${OUTPUT_DIR}"` left refdata/tmp missing, so vg
# failed with "couldn't create temp directory: refdata/tmp/vg-hS1GZi".
# `mkdir -p "${OUTPUT_DIR}/tmp"` creates both refdata/ and refdata/tmp/ in
# one call, since -p creates every intermediate directory.

echo "=== 0. Sanity-check inputs ==="
for f in tiny.gfa tiny.fa tiny.vcf.gz; do
    if [[ ! -f "${INPUT_DIR}/${f}" ]]; then
        echo "ERROR: expected ${INPUT_DIR}/${f} -- not found. Check INPUT_DIR/tiny." >&2
        exit 1
    fi
done
ls -la "${INPUT_DIR}"

echo -e "\n=== 1. vg autoindex -- build the giraffe index bundle from FASTA+VCF ==="
echo "(command shape confirmed against https://hackmd.io/@jeizenga/SyLMMC9N3," \
     "run literally against this tiny dataset there)"

# Workflow name is version-dependent (see update note above) -- probe
# --help rather than hardcode "giraffe" or "sr-giraffe".
AUTOINDEX_HELP="$(singularity exec "${VG_CONTAINER}" vg autoindex --help 2>&1 || true)"
if echo "${AUTOINDEX_HELP}" | grep -qw 'sr-giraffe'; then
    WORKFLOW="sr-giraffe"
elif echo "${AUTOINDEX_HELP}" | grep -qw 'giraffe'; then
    WORKFLOW="giraffe"
else
    echo "ERROR: neither 'giraffe' nor 'sr-giraffe' found in 'vg autoindex --help' workflow choices:" >&2
    echo "${AUTOINDEX_HELP}" >&2
    exit 1
fi
echo "Using --workflow ${WORKFLOW}"

singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg autoindex \
        --workflow "${WORKFLOW}" \
        --ref-fasta "${INPUT_DIR}/tiny.fa" \
        --vcf "${INPUT_DIR}/tiny.vcf.gz" \
        --prefix "${OUTPUT_DIR}/${PREFIX}" \
        --tmp-dir "${OUTPUT_DIR}/tmp"

echo -e "\n=== 2. Discover what autoindex actually produced (assumption 3) ==="
GBZ_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.gbz' | head -n1)"
DIST_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.dist' | head -n1)"
MIN_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.min' | head -n1)"
ZIP_FILE="$(find "${OUTPUT_DIR}" -maxdepth 1 -name '*.zipcodes' | head -n1)"

echo "GBZ:      ${GBZ_FILE:-<not found>}"
echo "DIST:     ${DIST_FILE:-<not found>}"
echo "MIN:      ${MIN_FILE:-<not found>}"
echo "ZIPCODES: ${ZIP_FILE:-<not found -- will build below>}"

if [[ -z "${GBZ_FILE}" || -z "${DIST_FILE}" || -z "${MIN_FILE}" ]]; then
    echo "ERROR: autoindex did not produce one of .gbz/.dist/.min -- inspect ${OUTPUT_DIR} and the job log above." >&2
    exit 1
fi

echo -e "\n=== 3. Zipcodes fallback (assumption 4) -- only runs if step 2 found none ==="
# Best-effort: https://hackmd.io/@jeizenga/SyLMMC9N3's own `vg giraffe`
# mapping example doesn't pass a zipcodes flag at all, so it's unclear
# whether this vg version's giraffe mapping (or the pinned pbrun version)
# actually requires one. Probe before attempting, warn-and-continue
# rather than failing the job if -z isn't supported here.
if [[ -z "${ZIP_FILE}" ]]; then
    MINIMIZER_HELP="$(singularity exec "${VG_CONTAINER}" vg minimizer --help 2>&1 || true)"
    if echo "${MINIMIZER_HELP}" | grep -q -- '--zipcode-name\|-z '; then
        ZIP_FILE="${OUTPUT_DIR}/${PREFIX}.zipcodes"
        singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
            vg minimizer \
                --distance-index "${DIST_FILE}" \
                --zipcode-name "${ZIP_FILE}" \
                --output-name "${MIN_FILE}" \
                "${GBZ_FILE}"
        echo "Built ${ZIP_FILE}"
    else
        echo "WARNING: this vg version's 'vg minimizer --help' doesn't show" \
             "-z/--zipcode-name -- skipping. Confirm separately whether" \
             "pbrun giraffe on this account's Parabricks version actually" \
             "requires --zipcodes-name (specs_dev.md Tier 0.5) before" \
             "assuming this is fine to skip."
    fi
else
    echo "Zipcodes already present from autoindex -- no fallback needed."
fi

echo -e "\n=== 4. Reference-paths list (--ref-paths input for pbrun giraffe) ==="
REF_PATHS_FILE="${OUTPUT_DIR}/${PREFIX}.ref_paths.txt"
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths --list --xg "${GBZ_FILE}" > "${REF_PATHS_FILE}"
cat "${REF_PATHS_FILE}"

echo -e "\n=== 5. Graph-derived reference FASTA (specs_dev.md section 4c/5b) ==="
REF_FASTA="${OUTPUT_DIR}/${PREFIX}.ref.fa"
singularity exec -B "$(pwd)" "${VG_CONTAINER}" \
    vg paths --extract-fasta --xg "${GBZ_FILE}" > "${REF_FASTA}"

module purge
module load "${SAMTOOLS_MODULE}"
samtools faidx "${REF_FASTA}"
samtools dict "${REF_FASTA}" > "${REF_FASTA%.fa}.dict"

echo -e "\n=== Done -- summary ==="
ls -la "${OUTPUT_DIR}"
echo ""
echo "graph_gbz       = ${GBZ_FILE}"
echo "graph_dist      = ${DIST_FILE}"
echo "graph_min       = ${MIN_FILE}"
echo "graph_zipcodes  = ${ZIP_FILE:-<none built -- see step 3 warning above>}"
echo "graph_ref_paths = ${REF_PATHS_FILE}"
echo "ref (for --ref) = ${REF_FASTA}  (+ .fai, .dict alongside)"
echo ""
echo "Feed these into tests/gpu_giraffe_smoketest/'s Tier-1 pbrun giraffe"
echo "run (docs/Giraffe_implementation_specs_dev.md section 10)."
echo ""
echo "Note (from https://hackmd.io/@jeizenga/SyLMMC9N3): open-source"
echo "'vg giraffe' maps to graph coordinates and needs 'vg surject -x"
echo "${GBZ_FILE} -F ${REF_PATHS_FILE} -b in.gam > out.bam' to project"
echo "onto the linear reference paths. pbrun giraffe's --out-bam is"
echo "documented as already linear/coordinate-sorted, so this shouldn't"
echo "be needed for the pbrun path -- but it's a useful cross-check if"
echo "Tier 2's BAM ever looks wrong: surject a small vg-giraffe-mapped"
echo ".gam with this graph and diff coordinates against pbrun's BAM."
