#!/bin/bash
#-------------------------------------------------------------------
# make_germline_synth_af.sh -- build a tiny SYNTHETIC Mutect2 germline
# resource (an af-only-gnomad stand-in) from the smoke-test sample's own
# Mutect2 sites.
#
# What it does:
#   1. takes the biallelic sites of an existing Mutect2 VCF of the smoke-test
#      tumor/normal pair (sites only: genotypes, INFO and FILTER stripped);
#   2. keeps every Nth site (default every 2nd) and gives it INFO/AF=<AF>
#      (default 0.1);
#   3. writes <outdir>/germline_synth_af.vcf.gz + .tbi -- usable as
#      params.germline_resource -- plus the annotated-site list
#      <outdir>/germline_synth_af.sites.tsv.gz (+ .tbi) for checking.
#
# Why this is a SHARPER test than real gnomAD: the expected answer is known.
# In a run WITHOUT --pon, every annotated site that is called should carry
# POPAF = -log10(AF) (1.00 for the default AF 0.1), every other site keeps
# Mutect2's default POPAF, and FilterMutectCalls' `germline` filter should hit
# annotated sites far more often than the rest. See README.md for the checks.
#
# Why AF defaults to 0.1: GetPileupSummaries (PREPON, which reads the same
# germline_resource) only uses sites with 0.01 <= AF <= 0.2 by default, so a
# value inside that range also gives the contamination step real sites. 0.1
# also gives the round POPAF 1.00. Use AF=0.4 etc. for a stronger germline
# signal, at the cost of PREPON seeing no sites.
#
# The source VCF must come from the SAME reference as the pipeline run
# (its ##contig lines are kept, and Mutect2 checks them against the .dict).
# Prefer a run WITHOUT --pon (all ~4893 smoke-test sites); the 3293-site
# PON-run VCF also works.
#
# Usage:
#   bash make_germline_synth_af.sh <source_mutect2.vcf.gz> <outdir>
#   AF=0.4 EVERY=3 bash make_germline_synth_af.sh <src.vcf.gz> <outdir>
#   BCFTOOLS_SIF=/path/bcftools-1.23--h3a4d415_0.sif bash ...   # no bcftools/tabix/bgzip on PATH
#
# Requires bcftools, bgzip and tabix (all three ship in the bcftools image).
#-------------------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail

SRC="${1:?usage: bash make_germline_synth_af.sh <source_mutect2.vcf.gz> <outdir>}"
OUT="${2:?usage: bash make_germline_synth_af.sh <source_mutect2.vcf.gz> <outdir>}"
AF="${AF:-0.1}"
EVERY="${EVERY:-2}"
BCFTOOLS_SIF="${BCFTOOLS_SIF:-/projects/ec232/ngs/ngs_singularity/bcftools-1.23--h3a4d415_0.sif}"

[[ -s "$SRC" ]] || { echo "ERROR: source VCF not found: $SRC" >&2; exit 1; }
awk -v a="$AF" 'BEGIN { exit !(a > 0 && a < 1) }' || { echo "ERROR: AF must be in (0,1), got $AF" >&2; exit 1; }
[[ "$EVERY" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: EVERY must be a positive integer, got $EVERY" >&2; exit 1; }
mkdir -p "$OUT"
SRC_REAL="$(realpath "$SRC")"; OUT_REAL="$(realpath "$OUT")"

# ---- tools: PATH, else the bcftools container ----
if command -v bcftools >/dev/null && command -v bgzip >/dev/null && command -v tabix >/dev/null; then
    run() { "$@"; }
elif command -v singularity >/dev/null && [[ -f "$BCFTOOLS_SIF" ]]; then
    run() { singularity exec -B "$(dirname "$SRC_REAL")" -B "$OUT_REAL" "$BCFTOOLS_SIF" "$@"; }
else
    echo "ERROR: need bcftools/bgzip/tabix on PATH or a usable BCFTOOLS_SIF ($BCFTOOLS_SIF)" >&2; exit 1
fi

SITES="$OUT_REAL/germline_synth_af.allsites.vcf.gz"
TSV="$OUT_REAL/germline_synth_af.sites.tsv.gz"
HDR="$OUT_REAL/germline_synth_af.af.hdr"
RES="$OUT_REAL/germline_synth_af.vcf.gz"

echo "source: $SRC_REAL"
echo "AF=$AF  every ${EVERY} site(s)  ->  $RES"

# 1. biallelic, sites-only, no INFO/FILTER (keeps ##contig lines)
run bcftools view -G -m2 -M2 -e 'ALT="*"' "$SRC_REAL" -Ou \
  | run bcftools annotate -x INFO,FILTER -Oz -o "$SITES"
run tabix -f -p vcf "$SITES"

# 2. every Nth site gets AF (CHROM POS REF ALT AF; already coordinate-sorted)
run bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' "$SITES" \
  | awk -v n="$EVERY" -v af="$AF" 'BEGIN{OFS="\t"} (NR-1) % n == 0 { print $0, af }' \
  | run bgzip -c > "$TSV"
run tabix -f -s1 -b2 -e2 "$TSV"

# 3. annotate, keep only the annotated sites, index
printf '##INFO=<ID=AF,Number=A,Type=Float,Description="Allele frequency in the population (SYNTHETIC, make_germline_synth_af.sh, AF=%s)">\n' "$AF" > "$HDR"
run bcftools annotate -a "$TSV" -c CHROM,POS,REF,ALT,INFO/AF -h "$HDR" "$SITES" -Ou \
  | run bcftools view -i 'INFO/AF>0' -Oz -o "$RES"
run tabix -f -p vcf "$RES"

rm -f "$SITES" "$SITES.tbi" "$HDR"

n_src=$(run bcftools view -H "$SRC_REAL" | wc -l)
n_res=$(run bcftools view -H "$RES" | wc -l)
n_af=$(run bcftools query -f '%INFO/AF\n' "$RES" | sort -u | tr '\n' ' ')
echo
echo "source records:            $n_src"
echo "synthetic resource sites:  $n_res   (INFO/AF values: $n_af)"
echo "expected POPAF at those:   $(awk -v a="$AF" 'BEGIN { printf "%.2f", -log(a)/log(10) }')"
echo
echo "Use as:  germline_resource: $RES"
echo "Run the somatic pipeline WITHOUT --pon, then see README.md for the checks."
