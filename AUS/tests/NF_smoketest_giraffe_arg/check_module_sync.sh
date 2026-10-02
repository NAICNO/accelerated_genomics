#!/bin/bash
# -------------------------------------------------
# check_module_sync.sh
# -------------------------------------------------
# Drift check between nf_giraffe_arg_smoketest.nf's stubs and the real code.
# The stubs define what the real modules must contain. This script greps the
# real files for the same flags/patterns.
#
# It turns GREEN when they are written to match the stubs. After that it
# guards against the stub/module drift noted in the exome test's "Known gap".
#
# Usage: from this directory, ./check_module_sync.sh

set -o nounset
set -o pipefail

cd "$(dirname "$0")"
REPO_ROOT="../.."
fail=0

pass() { echo "  ok   $1"; }
miss() { echo "  FAIL $1"; fail=1; }

code() { grep -vE '^[[:space:]]*(\*|//|/\*)' "$1"; }  # file minus comment lines

must_have() {  # file, fixed-string pattern, description -- code only, not comments
  if [ -f "$1" ] && code "$1" | grep -qF -- "$2"; then pass "$3"; else miss "$3"; fi
}
must_not_have() {  # ignores comment lines, so a module may document WHY a flag is absent
  if [ -f "$1" ] && ! code "$1" | grep -qE -- "$2"; then pass "$3"; else miss "$3"; fi
}

GIRAFFE="$REPO_ROOT/modules/giraffe.nf"
echo "modules/giraffe.nf"
if [ -f "$GIRAFFE" ]; then pass "file exists"; else miss "file exists"; fi
must_have "$GIRAFFE" "process GIRAFFE"            "process GIRAFFE defined"
must_have "$GIRAFFE" "label 'gpu_process'"        "label 'gpu_process'"
must_have "$GIRAFFE" "container params.parabricks_container" "pinned parabricks container"
for flag in "pbrun giraffe" "--in-fq" "--gbz-name" "--dist-name" "--minimizer-name" \
            "--zipcodes-name" "--ref-paths" "--out-bam" "--out-duplicate-metrics" \
            "--sample" "--read-group" "--num-gpus" "--tmp-dir"; do
  must_have "$GIRAFFE" "$flag" "uses $flag"
done
must_not_have "$GIRAFFE" '--read-group-sm'     "no --read-group-sm (does not exist in 4.7.1-1)"
must_not_have "$GIRAFFE" '--ref[[:space:]]'     "no --ref (spec 4c)"
must_not_have "$GIRAFFE" '--interval-file'      "no --interval-file (spec 5c)"
must_not_have "$GIRAFFE" '--in-se-fq'           "paired-end only (no --in-se-fq)"
must_have "$GIRAFFE" 'publishDir { "${params.outdir}/bam/${params.germline_mapping}/${sample_id}" }' \
          "publishDir nested by germline_mapping (closure form)"
must_have "$GIRAFFE" 'path("${sample_id}.bam.bai")' "emits .bai (written by pbrun, Tier 1)"

echo "modules/fq2bam.nf, modules/applybqsr.nf (shared with somatic)"
must_have "$REPO_ROOT/modules/fq2bam.nf" \
  'publishDir { "${params.outdir}/bam/${params.germline_mapping ?: '"'fq2bam'"'}/${sample_id}" }' \
  "fq2bam publishDir with elvis fallback"
must_have "$REPO_ROOT/modules/applybqsr.nf" \
  'publishDir { "${params.outdir}/bam_recal/${params.germline_mapping ?: '"'fq2bam'"'}/${sample_id}" }' \
  "applybqsr publishDir with elvis fallback"

WF="$REPO_ROOT/germline_workflow.nf"
echo "germline_workflow.nf"
must_have "$WF" "include { GIRAFFE"                          "includes GIRAFFE"
must_have "$WF" "include { FQ2BAM"                           "still includes FQ2BAM"
must_have "$WF" "'germline_mapping'"                         "germline_mapping in required list"
must_have "$WF" "params.germline_mapping !in ['giraffe', 'fq2bam']" "enum check"
must_have "$WF" "def graph_params = ['graph_gbz', 'graph_dist', 'graph_min', 'graph_zipcodes', 'graph_ref_paths']" \
          "graph_* conditional-requirement list"
must_have "$WF" "ch_aligned_bam = GIRAFFE.out.bam"           "giraffe branch feeds ch_aligned_bam"
must_have "$WF" "ch_aligned_bam = FQ2BAM.out.bam"            "fq2bam branch feeds ch_aligned_bam"
must_have "$WF" "BQSR(ch_aligned_bam"                        "BQSR consumes ch_aligned_bam"

CFG="$REPO_ROOT/germline.config"
echo "germline.config"
must_have "$CFG" "germline_mapping = 'fq2bam'" "germline_mapping default 'fq2bam'"
for p in graph_gbz graph_dist graph_min graph_zipcodes graph_ref_paths; do
  if [ -f "$CFG" ] && code "$CFG" | grep -qE "^\s*${p}\s*=\s*null"; then pass "$p = null"; else miss "$p = null"; fi
done

echo
if [ "$fail" -ne 0 ]; then
  echo "RED: real code does not match nf_giraffe_arg_smoketest.nf's stubs yet."
  exit 1
fi
echo "GREEN: real code matches nf_giraffe_arg_smoketest.nf's stubs."
