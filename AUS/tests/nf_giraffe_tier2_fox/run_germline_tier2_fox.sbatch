#!/bin/bash
#-------------------------------------------------------------------
# run_germline_tier2_fox.sbatch -- Nextflow head job for Tier 2.
# Runs germline_workflow.nf with the given params file; the pipeline's own
# GPU tasks are submitted as separate Slurm jobs by Nextflow (-profile fox).
#
# Usage (from this directory):
#   NXF=/path/to/nextflow sbatch run_germline_tier2_fox.sbatch params.giraffe_fox.yaml
#   NXF=/path/to/nextflow sbatch run_germline_tier2_fox.sbatch params.fq2bam_fox.yaml
# Extra args after the params file are passed to nextflow (e.g. -resume).
#-------------------------------------------------------------------
#SBATCH -J nf_giraffe_tier2
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH -t 03:00:00
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

set -o errexit
set -o nounset
set -o pipefail

cd "${SLURM_SUBMIT_DIR:-$(pwd)}"
PARAMS="${1:?usage: sbatch run_germline_tier2_fox.sbatch <params.yaml> [nextflow args]}"
shift
NXF="${NXF:-nextflow}"
REPO="$(cd ../.. && pwd)"
TAG="$(basename "$PARAMS" .yaml)"

echo "Nextflow: $("$NXF" -v 2>&1 | tail -1)"
echo "Repo:     $REPO @ $(git -C "$REPO" --no-optional-locks log --oneline -1 2>/dev/null || echo '?')"
echo "Params:   $PARAMS"

"$NXF" run "$REPO/germline_workflow.nf" \
    -c "$REPO/germline.config" \
    -profile singularity,fox,test \
    -params-file "$PARAMS" \
    -with-report "report_${TAG}.html" \
    -with-timeline "timeline_${TAG}.html" \
    "$@"

# germline.config's trace file is overwritten by every run into the same outdir --
# keep a per-aligner copy.
OUTDIR="$(grep -E '^outdir:' "$PARAMS" | awk '{print $2}')"
cp "${OUTDIR}/pipeline_info/trace.txt" "trace_${TAG}.txt"
echo "Trace copied to trace_${TAG}.txt"
