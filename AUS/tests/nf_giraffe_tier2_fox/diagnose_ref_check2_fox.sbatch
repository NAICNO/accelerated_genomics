#!/bin/bash
#-------------------------------------------------------------------
# diagnose_ref_check2_fox.sbatch -- why did build_primary_ref_fox.sbatch
# report "CHECK 2 sequences == source FASTA: DIFFER"?
# Plan and decision table: tier2-fox-runbook_result_records.md, "CHECK 2 diagnosis".
#
# HL  Line wrapping only: vg writes 80 bases/line, `samtools faidx` keeps the
#     input's width, so the graph extract is 80-col; if the source FASTA is not
#     80-col, CHECK 2's byte-level cmp reports DIFFER for identical sequence.
#     (The graph FASTA's size, 3,126,873,374 bytes, is exactly GRCh38 chr1-22,X,Y
#     wrapped at 80.) compare_fasta_bases.py ignores wrapping.
# H0  CHECK 2 compared against the wrong source: the graph was built from
#     tiny_ref/Homo_sapiens_assembly38.fasta (build_giraffe_refs_vg1.77.sh),
#     CHECK 2 used parabricks_ref/Homo_sapiens_assembly38.fasta.
# H1  Only IUPAC ambiguity codes (M, R, Y, ...) in GRCh38 became N in the graph.
# H2  Real sequence differences (N<->base, substitutions).
#
# Steps: 1 identity of the two source FASTAs; 2 extract the 24 primary
# contigs from each; 3 classify every differing base (compare_fasta_bases.py)
# graph vs each source; 4 impact: Tier 2 calls/coverage on differing sites.
#
# Usage (from this directory): sbatch diagnose_ref_check2_fox.sbatch
# Results: $WORK/tiny_ref/check2_diag/ and this job's .out (grep -E "VERDICT|MD5|STEP")
#-------------------------------------------------------------------
#SBATCH -J giraffe_check2_diag
#SBATCH --account=ec232
#SBATCH --partition=normal
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH -t 01:00:00
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

set -o errexit
set -o nounset
set -o pipefail

HERE="${SLURM_SUBMIT_DIR:-$(pwd)}"
WORK=${WORK:-/projects/ec232/ngs/analysis/AUS/girrfe_mapper/vg_mapping_exercises}
P="${WORK}/tiny_ref/Homo_sapiens_assembly38"
GRAPH_FA="${P}.primary.gbz.fa"
PATHS="${P}.primary.paths"
SRC_BUILD="${WORK}/tiny_ref/Homo_sapiens_assembly38.fasta"                        # what the graph was built from
SRC_PB=${SRC_PB:-/projects/ec232/ngs/reference/parabricks_ref/Homo_sapiens_assembly38.fasta}  # what CHECK 2 used (and fq2bam)
OUT="${WORK}/tiny_ref/check2_diag"
# Tier 2 outputs (for step 4); adjust if your launch dir differs
T2_OUT="${T2_OUT:-${HERE}/results_tier2}"

module purge 2>/dev/null || true
module load SAMtools/1.17-GCC-12.2.0 2>/dev/null || echo "NOTE: SAMtools module not loaded -- using $(command -v samtools || echo 'NO samtools')"
mkdir -p "$OUT"

echo "STEP 1 -- are the two source FASTAs the same file?"
for f in "$SRC_BUILD" "$SRC_PB"; do
    [[ -s "$f" ]] || { echo "MISSING $f"; continue; }
    [[ -s "$f.fai" ]] || samtools faidx "$f"
    echo "MD5 $(md5sum "$f" | cut -d' ' -f1)  $(stat -c %s "$f") bytes  $f"
    [[ -L "$f" ]] && echo "     (symlink -> $(readlink -f "$f"))"
done
if [[ -s "$SRC_BUILD" && -s "$SRC_PB" ]]; then
    diff <(awk -v L="$(paste -sd'|' "$PATHS")" 'BEGIN{split(L,a,"|");for(i in a)k[a[i]]=1} $1 in k{print $1"\t"$2}' "$SRC_BUILD.fai") \
         <(awk -v L="$(paste -sd'|' "$PATHS")" 'BEGIN{split(L,a,"|");for(i in a)k[a[i]]=1} $1 in k{print $1"\t"$2}' "$SRC_PB.fai") \
        && echo "primary contig names/lengths identical in both .fai" || echo "primary contig names/lengths DIFFER between the two sources"
fi

echo "LINE WIDTHS (bases per line, .fai column 4; chr1 row) -- a byte-level cmp fails whenever these differ:"
for f in "$GRAPH_FA" "$SRC_BUILD" "$SRC_PB"; do
    [[ -s "$f.fai" ]] && echo "  $(awk '$1=="chr1"{print $4}' "$f.fai")  $f"
done

echo "STEP 2 -- extract the 24 primary contigs (same order and 60-col layout as the graph FASTA)"
for tag in build pb; do
    src=$([[ $tag == build ]] && echo "$SRC_BUILD" || echo "$SRC_PB")
    [[ -s "$src" ]] || continue
    samtools faidx "$src" $(cat "$PATHS") > "$OUT/source_${tag}.primary.fa"
done

echo "STEP 3 -- classify differences (graph vs each source)"
for tag in build pb; do
    [[ -s "$OUT/source_${tag}.primary.fa" ]] || continue
    echo "--- graph vs source_${tag}"
    python3 "$HERE/compare_fasta_bases.py" "$GRAPH_FA" "$OUT/source_${tag}.primary.fa" "$OUT/graph_vs_${tag}"
    echo "first differing sites:"; head -6 "$OUT/graph_vs_${tag}.diffs.tsv"
done

echo "STEP 4 -- impact on Tier 2 (sites from graph_vs_build, or graph_vs_pb if build missing)"
D="$OUT/graph_vs_build.diffs.tsv"; [[ -s "$D" ]] || D="$OUT/graph_vs_pb.diffs.tsv"
NSITES=$(( $(wc -l < "$D") - 1 ))
echo "non-case differing sites: $NSITES"
if (( NSITES > 0 )); then
    for m in giraffe fq2bam; do
        for c in deepvariant haplotypecaller; do
            V="$T2_OUT/vcf/$m/$c/SAMPLE01.$c.vcf"
            [[ -s "$V" ]] || { echo "$m $c: no VCF at $V"; continue; }
            n=$(awk -F'\t' 'NR==FNR{if(FNR>1)s[$1":"$2]=1; next} !/^#/ && ($1":"$2) in s' "$D" "$V" | wc -l)
            echo "$m $c: $n calls at differing sites"
        done
    done
    BAM="$T2_OUT/bam/giraffe/SAMPLE01/SAMPLE01.bam"
    if [[ -s "$BAM" ]]; then
        cut -f1-3 "${D%.tsv}.bed" > "$OUT/sites.bed" 2>/dev/null || true
        echo "giraffe BAM depth at differing sites (sites with depth>0 / total):" \
             "$(samtools depth -b "$OUT/sites.bed" "$BAM" | awk '$3>0' | wc -l) / $NSITES"
    fi
fi

echo "STEP 5 -- summary (VERDICT lines above: graph vs build source, graph vs parabricks_ref source)"
echo "Summaries: $OUT/graph_vs_*.summary.tsv   Sites: $OUT/graph_vs_*.diffs.tsv"
echo "Clean up the two ~3 GB extracts when done: rm $OUT/source_*.primary.fa"
