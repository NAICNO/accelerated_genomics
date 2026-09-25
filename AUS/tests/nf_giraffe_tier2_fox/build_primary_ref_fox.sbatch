#!/bin/bash
#-------------------------------------------------------------------
# build_primary_ref_fox.sbatch -- Tier 2 prerequisite
# (docs/Giraffe_tier2_context.md section 3a).
#
# Builds the 24-contig params.ref for --germline_mapping giraffe:
# FASTA extracted from the SAME graph as the Tier 1 index bundle,
# restricted to Homo_sapiens_assembly38.primary.paths (chr1..22,X,Y) and
# forced into that order, plus .fai and .dict. The step-4 .gbz.fa from
# docs/issues/issues_103/build_giraffe_refs_vg1.77.sh is NOT usable (it keeps
# the IMGT/HLA records, ~51 GB).
#
# Checks printed at the end (look for "CHECK"):
#   1. contig names/order in the .fai == primary.paths
#   2. sequences vs the source Homo_sapiens_assembly38.fasta (graph was built
#      FASTA-only, so they should match; case-only differences are reported
#      separately and are harmless for bqsr/callers)
#
# Usage (from anywhere): sbatch build_primary_ref_fox.sbatch
#-------------------------------------------------------------------
#SBATCH -J giraffe_primary_ref
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH -t 02:00:00
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

set -o errexit
set -o nounset
set -o pipefail

WORK=/projects/ec232/ngs/analysis/AUS/girrfe_mapper/vg_mapping_exercises
SOURCE_FASTA=/projects/ec232/ngs/reference/parabricks_ref/Homo_sapiens_assembly38.fasta
VG_SIF="${WORK}/vg_v1.70.0.sif"          # same vg that built the bundle (build_giraffe_refs_vg1.77.sh)
SAMTOOLS_MODULE="SAMtools/1.17-GCC-12.2.0"

P="${WORK}/tiny_ref/Homo_sapiens_assembly38"
GBZ="${P}.autoindex.1.70.giraffe.gbz"
PATHS="${P}.primary.paths"
OUT="${P}.primary.gbz.fa"
DICT="${P}.primary.gbz.dict"             # germline_workflow.nf derives <ref minus .fa>.dict
TMP="${WORK}/tiny_ref/tmp_primary_$$"

for f in "$VG_SIF" "$GBZ" "$PATHS" "$SOURCE_FASTA"; do
    [[ -s "$f" ]] || { echo "ERROR: missing $f" >&2; exit 1; }
done
echo "primary.paths:"; cat "$PATHS" | tr '\n' ' '; echo

echo "=== 1. vg paths -F (graph -> FASTA, primary contigs only) ==="
singularity exec -B "${WORK}" "$VG_SIF" vg paths -x "$GBZ" -p "$PATHS" -F > "${TMP}.fa"

module purge
module load "$SAMTOOLS_MODULE"

echo "=== 2. force karyotypic order, index, dict ==="
samtools faidx "${TMP}.fa"
samtools faidx "${TMP}.fa" $(cat "$PATHS") > "$OUT"
samtools faidx "$OUT"
samtools dict "$OUT" > "$DICT"
ls -la "$OUT" "$OUT.fai" "$DICT"

echo "=== 3. checks ==="
if cut -f1 "$OUT.fai" | diff -q - "$PATHS" >/dev/null; then
    echo "CHECK 1 contigs/order == primary.paths: OK"
else
    echo "CHECK 1 contigs/order == primary.paths: FAIL"; cut -f1 "$OUT.fai" | diff - "$PATHS" || true
fi

samtools faidx "$SOURCE_FASTA" $(cat "$PATHS") > "${TMP}.source.fa"
if cmp -s "$OUT" "${TMP}.source.fa"; then
    echo "CHECK 2 sequences == source FASTA: OK (byte-identical)"
elif cmp -s <(tr 'a-z' 'A-Z' < "$OUT") <(tr 'a-z' 'A-Z' < "${TMP}.source.fa"); then
    echo "CHECK 2 sequences == source FASTA: OK ignoring case (soft-masking differs; harmless)"
else
    echo "CHECK 2 sequences == source FASTA: DIFFER -- do not use for Tier 2, investigate"
fi
cut -f1,2 "$OUT.fai"

rm -f "${TMP}.fa" "${TMP}.fa.fai" "${TMP}.source.fa"
echo "Done: params.ref = $OUT"
