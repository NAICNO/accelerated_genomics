#!/bin/bash
# -------------------------------------------------
# check_stub_sync.sh
# -------------------------------------------------
# nf_resource_sweep_verification.nf's stub process list is hand-maintained,
# not generated from modules/*.nf. If a process is added, removed, or
# relabeled in the real pipeline without updating the stub list, the
# sweep test would silently cover less than it claims to -- no error, just
# a TSV missing a row, or a row with the wrong label. Run this before
# trusting any sweep run's results, especially before a release.
#
# Usage: from this directory, ./check_stub_sync.sh

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")"
REPO_ROOT="../.."

# Expected process -> label, hand-copied from nf_resource_sweep_verification.nf's
# header comment. Keep these two in sync manually when the real pipeline
# changes -- this script only catches drift, it doesn't prevent it.
EXPECTED=$(cat <<'EOF'
FQ2BAM gpu_process
BQSR gpu_process
APPLYBQSR gpu_process
MUTECTCALLER gpu_process
DEEPSOMATIC gpu_process
DEEPVARIANT gpu_process
HAPLOTYPECALLER gpu_process
PREPON leaf_process
POSTPON leaf_process
VCFQC leaf_process
EOF
)

mismatch=0
module_glob="$REPO_ROOT"/modules/*.nf

# 1. Every real process name must be in EXPECTED, and vice versa.
real_names=$(grep -hE '^process [A-Za-z0-9_]+' $module_glob | sed -E 's/^process ([A-Za-z0-9_]+).*/\1/' | sort -u)
expected_names=$(printf '%s\n' "$EXPECTED" | awk '{ print $1 }' | sort -u)

if [ "$real_names" != "$expected_names" ]; then
  echo "MISMATCH: real pipeline process names differ from this verification test's stub list."
  echo "--- modules/*.nf (real) ---"
  echo "$real_names"
  echo "--- nf_resource_sweep_verification.nf stub list (expected) ---"
  echo "$expected_names"
  echo
  echo "diff (real vs expected):"
  diff <(echo "$real_names") <(echo "$expected_names") || true
  mismatch=1
fi

# 2. Each real process's label must match what the stub uses.
while read -r name expected_label; do
  module_file=$(grep -lE "^process ${name}([[:space:]]|\{)" $module_glob 2>/dev/null || true)
  if [ -z "$module_file" ]; then
    continue  # already reported as a name mismatch above
  fi
  # A process can be defined in more than one file (e.g. VCFQC in both
  # germline_vcfqc.nf and somatic_vcfqc.nf) -- check every definition.
  while read -r f; do
    real_label=$(sed -n "s/^[[:space:]]*label '\([a-zA-Z0-9_][a-zA-Z0-9_]*\)'.*/\1/p" "$f" | head -1)
    if [ "$real_label" != "$expected_label" ]; then
      echo "MISMATCH: $name in $f has label '$real_label', stub expects '$expected_label'"
      mismatch=1
    fi
  done <<EOF
$module_file
EOF
done <<EOF
$EXPECTED
EOF

if [ "$mismatch" -ne 0 ]; then
  echo
  echo "Update nf_resource_sweep_verification.nf's process stubs AND this" \
       "script's EXPECTED array to match modules/*.nf before trusting a" \
       "sweep run."
  exit 1
fi

expected_count=$(printf '%s\n' "$EXPECTED" | wc -l | awk '{ print $1 }')
echo "OK: stub process list and labels match modules/*.nf (${expected_count} processes)."
