#!/bin/bash
#-------------------------------------------------------------------
#
# Builds the 24-contig params.ref for --germline_mapping giraffe:
# FASTA extracted from the SAME graph as the `tiny_ref`` index bundle,
# restricted to Homo_sapiens_assembly38.primary.paths (chr1..22,X,Y) and
# forced into that order, plus .fai and .dict.
#
# Checks printed at the end (look for "CHECK"):
#   1. contig names/order in the .fai == primary.paths
#   2. bases vs the FASTA the graph was built from (compare_fasta_bases.py:
#      ignores line wrapping and case; IUPAC->N accepted as expected vg behaviour)
#
# Usage (from this directory -- it needs compare_fasta_bases.py): sbatch build_primary_ref_fox.sbatch
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
# The FASTA the graph was actually built from (AUS/tests/PBrun_giraffe_smoketest/build_giraffe_refs_vg1.70.sh:
# REF_FASTA=tiny_ref/Homo_sapiens_assembly38.fasta).
SOURCE_FASTA="${WORK}/tiny_ref/Homo_sapiens_assembly38.fasta"
HERE="${SLURM_SUBMIT_DIR:-$(pwd)}"    # holds compare_fasta_bases.py
VG_SIF="${WORK}/vg_v1.70.0.sif"          # same vg that built the bundle (build_giraffe_refs_vg1.70.sh)
SAMTOOLS_MODULE="SAMtools/1.17-GCC-12.2.0"

P="${WORK}/tiny_ref/Homo_sapiens_assembly38"
GBZ="${P}.autoindex.1.70.giraffe.gbz"
PATHS="${P}.primary.paths"
OUT="${P}.primary.gbz.fa"
DICT="${P}.primary.gbz.dict"             # germline_workflow.nf derives <ref minus .fa>.dict
TMP="${WORK}/tiny_ref/tmp_primary_$$"

for f in "$VG_SIF" "$GBZ" "$PATHS" "$SOURCE_FASTA" "$HERE/compare_fasta_bases.py"; do
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

# CHECK 2 compares bases, not bytes: vg writes 80 bases/line and samtools faidx keeps the
# input's width, so a byte-level cmp against a 60-col source reported DIFFER for identical
samtools faidx "$SOURCE_FASTA" $(cat "$PATHS") > "${TMP}.source.fa"
V=$(python3 "$HERE/compare_fasta_bases.py" "$OUT" "${TMP}.source.fa" "${TMP}.cmp" | tee /dev/stderr | grep '^VERDICT')
case "$V" in
    *"IDENTICAL"*|*"ONLY IUPAC->N"*) echo "CHECK 2 sequences == source FASTA: OK -- ${V#VERDICT }" ;;
    *) echo "CHECK 2 sequences == source FASTA: DIFFER -- ${V#VERDICT } (sites: ${TMP}.cmp.diffs.tsv)" ;;
esac
cut -f1,2 "$OUT.fai"

rm -f "${TMP}.fa" "${TMP}.fa.fai" "${TMP}.source.fa" "${TMP}.source.fa.fai"
echo "Done: params.ref = $OUT"
