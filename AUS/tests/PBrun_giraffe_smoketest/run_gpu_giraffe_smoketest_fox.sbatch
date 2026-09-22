#!/bin/bash
#-------------------------------------------------------------------
#-------------------------------------------------------------------
# run_gpu_giraffe_smoketest_fox -- runs a single real Parabricks GPU
# tool (`pbrun giraffe`) against a real reference-graph bundle via
# Singularity, no Nextflow involved. Standalone SLURM job, same
# "bypass the pipeline, test the real tool directly"
#
# Cluster/container conventions mirrored from configs/PARABRICKS_FOX.conf
# (account ec232, `accel` partition, generic `--gpus=1`, `-B /localscratch
# --nv` containerOptions) and from the CUDA_VISIBLE_DEVICES env
# pass-through pattern in gpu_fq2bam_smoketest's TSD script (SINGULARITYENV_
# + APPTAINERENV_ prefixes, since TSD's `singularity` turned out to be
# Apptainer under the hood -- see tests/gpu_diag_smoketest).
#
#-------------------------------------------------------------------
#SBATCH -J stest-gpu_giraffe
#SBATCH --account=ec232
#SBATCH --partition=accel
#SBATCH --gpus=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH -t 00:10:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o errexit
set -o nounset
set -o pipefail
# errexit is appropriate here (matches gpu_fq2bam_smoketest's reasoning,
# not gpu_diag_smoketest's deliberate no-errexit diagnostic sweep): this
# script runs one real pbrun workload, and a partial/corrupt output
# silently continuing past a failure would be worse than the job stopping.

# ---- adjust these if your layout differs ----
CONTAINER="/projects/ec232/ngs/ngs_singularity/clara-parabricks_4.7.1-1.sif"
# Confirmed present at this path on Fox --
# docs/meta-resources/parabricks_v4.7.1_verification_runbook.md.

WORK_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
TMP_DIR="${WORK_DIR}/pbrun_tmp"
REFDATA_DIR="${WORK_DIR}/tiny_ref"
# Directory name is a leftover from the original tiny-dataset exercise --
# its contents are the real Homo_sapiens_assembly38-derived index (see
# UPDATED note above), not tiny/MHC data.
PREFIX="Homo_sapiens_assembly38"     # matches the reference-bundle filenames in tiny_ref/
FASTQ_DIR="${WORK_DIR}"
FASTQ_1="${FASTQ_DIR}/sample_normal_1.fastq.gz"
FASTQ_2="${FASTQ_DIR}/sample_normal_2.fastq.gz"
SAMPLE_ID="GIRAFFE_NORMAL01"
OUT_BAM="${WORK_DIR}/${SAMPLE_ID}.bam"
OUT_DUP_METRICS="${WORK_DIR}/${SAMPLE_ID}.duplicate_metrics.txt"

cd "$WORK_DIR"
mkdir -p "$TMP_DIR"

echo "Running on host: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Assigned GPU: ${CUDA_VISIBLE_DEVICES:-<unset>}"
echo "Container: $CONTAINER"

echo -e "\n=== 0. Sanity-check inputs ==="

echo "-- reference bundle (discovered by pattern under ${REFDATA_DIR}, not hardcoded name) --"
GBZ_FILE="$(find "${REFDATA_DIR}" -maxdepth 1 -name "${PREFIX}*.gbz" | head -n1)"
DIST_FILE="$(find "${REFDATA_DIR}" -maxdepth 1 -name "${PREFIX}*.dist" | head -n1)"
MIN_FILE="$(find "${REFDATA_DIR}" -maxdepth 1 -name "${PREFIX}*.min" | head -n1)"
ZIP_FILE="$(find "${REFDATA_DIR}" -maxdepth 1 -name "${PREFIX}*.zipcodes" | head -n1)"
#REF_PATHS_FILE="$(find "${REFDATA_DIR}" -maxdepth 1 -name "${PREFIX}*.paths" | head -n1)"
REF_PATHS_FILE=${REFDATA_DIR}"/Homo_sapiens_assembly38.primary.paths"
for name in GBZ_FILE DIST_FILE MIN_FILE ZIP_FILE REF_PATHS_FILE; do
    if [[ -z "${!name}" ]]; then
        echo "ERROR: could not find a ${name%_FILE} file under ${REFDATA_DIR} matching ${PREFIX}*." >&2
        echo "Check REFDATA_DIR/PREFIX match your actual tiny_ref/ contents." >&2
        exit 1
    fi
done
echo "graph_gbz       = ${GBZ_FILE}"
echo "graph_dist      = ${DIST_FILE}"
echo "graph_min       = ${MIN_FILE}"
echo "graph_zipcodes  = ${ZIP_FILE}"
echo "graph_ref_paths = ${REF_PATHS_FILE}"

echo -e "\n-- paired-end FASTQ reads --"
if [[ ! -f "${FASTQ_1}" || ! -f "${FASTQ_2}" ]]; then
    echo "ERROR: expected ${FASTQ_1} and ${FASTQ_2} -- not found." >&2
    echo "This run is configured for the real sample_normal_1/2.fastq.gz" >&2
    echo "pair (same reads gpu_fq2bam_smoketest uses), not the tiny" >&2
    echo "fixture's .gam read simulations -- check FASTQ_DIR/FASTQ_1/FASTQ_2 above." >&2
    exit 1
fi
echo "fastq_1 = ${FASTQ_1}"
echo "fastq_2 = ${FASTQ_2}"

# --- Environment Pass-Through for Slurm GPU Binding ---
# Set both prefixes -- see header comment: confirmed necessary on TSD
# (tests/gpu_diag_smoketest), unconfirmed but harmless on Fox.
export SINGULARITYENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"
export APPTAINERENV_CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"

echo -e "\n=== 1. Run pbrun giraffe ==="
echo "Flags confirmed against 'singularity exec ${CONTAINER} pbrun giraffe -h'" \
     "run 2026-09-16 -- NOT the section 11 draft's guessed --read-group-sm" \
     "(that flag does not exist; --sample / --read-group do)."

singularity exec \
    --nv \
    -B /localscratch \
    -B "$WORK_DIR" \
    -B "$TMP_DIR" \
    -B "$REFDATA_DIR" \
    "$CONTAINER" \
    pbrun giraffe \
        --in-fq "${FASTQ_1}" "${FASTQ_2}" \
        --gbz-name "${GBZ_FILE}" \
        --dist-name "${DIST_FILE}" \
        --minimizer-name "${MIN_FILE}" \
        --zipcodes-name "${ZIP_FILE}" \
        --ref-paths "${REF_PATHS_FILE}" \
        --out-bam "${OUT_BAM}" \
        --out-duplicate-metrics "${OUT_DUP_METRICS}" \
        --sample "${SAMPLE_ID}" \
        --read-group "${SAMPLE_ID}" \
        --num-gpus 1 \
        --tmp-dir "$TMP_DIR"

echo "pbrun giraffe completed successfully."

echo -e "\n=== 2. Output BAM exists and is non-empty ==="
if [[ ! -s "${OUT_BAM}" ]]; then
    echo "ERROR: ${OUT_BAM} missing or empty." >&2
    exit 1
fi
ls -la "${OUT_BAM}"

echo -e "\n=== 3. Duplicate-metrics file exists and is non-empty ==="
# Confirms giraffe's default (no --no-markdups passed) actually performs
# duplicate marking, per section 5e's "coordinate-sorted BAM file with
# duplicate marking applied" docs quote.
if [[ ! -s "${OUT_DUP_METRICS}" ]]; then
    echo "ERROR: ${OUT_DUP_METRICS} missing or empty -- duplicate marking" >&2
    echo "may not have run as expected." >&2
    exit 1
fi
cat "${OUT_DUP_METRICS}"

echo -e "\n=== 4. .bai index check (resolves specs_dev.md section 5e / Tier 0.5 item 3) ==="
if [[ -f "${OUT_BAM}.bai" ]]; then
    echo "RESULT: pbrun giraffe DOES leave a .bai alongside the .bam automatically."
    ls -la "${OUT_BAM}.bai"
else
    echo "RESULT: pbrun giraffe does NOT leave a .bai alongside the .bam."
    echo "modules/giraffe.nf (section 11) will need an explicit indexing step" \
         "(e.g. 'samtools index') that fq2bam.nf doesn't need."
fi

echo -e "\n=== 5. BAM header -- confirm real pbrun giraffe version + resolved flags ==="
module purge
module load SAMtools 2>/dev/null || echo "NOTE: adjust samtools module name if this load fails (see SAMTOOLS_MODULE in build_giraffe_refdata_fox.sbatch)."
samtools view -H "${OUT_BAM}" | tee /dev/stderr | grep -i "giraffe" || {
    echo "WARNING: no giraffe @PG line found in BAM header -- inspect manually." >&2
}

echo -e "\n=== Done -- summary ==="
echo "out_bam             = ${OUT_BAM}"
echo "out_bam_bai_present = $([[ -f "${OUT_BAM}.bai" ]] && echo yes || echo no)"
echo "out_duplicate_metrics = ${OUT_DUP_METRICS}"
echo ""
echo "Record job accounting (sacct -j ${SLURM_JOB_ID} --format=JobID,Elapsed,MaxRSS,TotalCPU)"
echo "as the Tier 1 sanity-floor timing data (specs_dev.md section 8/10)."
echo ""
echo "Next: tests/gpu_giraffe_smoketest/'s Tier 2 (modules/giraffe.nf wired"
echo "into germline_workflow.nf, specs_dev.md section 10) -- not started."

