#!/bin/bash
#-------------------------------------------------------------------
# mutectcaller_verification_test.sh -- re-runnable check of the somatic
# Mutect2 branch after any change to Mutect2 parameters or wiring
#
#   MUTECTCALLER -> [PB_POSTPON] -> POSTPON (FilterMutectCalls)
#                -> LEARNORIENTATION --^
#
# What it checks (from the finished run's own files -- no re-run needed):
#   C1  MUTECTCALLER got --mutect-germline-resource; POPAF varies (not one constant).
#       If the germline resource has no INFO/AF (e.g. known_indels used as a
#       wiring-only stand-in), the POPAF check is SKIPPED, not failed -- C1 is then
#       only "wired", not "verified"; use an AF resource (af-only-gnomad) for that.
#   C2  with --pon: MUTECTCALLER got --pon; record count dropped vs the no-PON
#       baseline; PB_POSTPON flagged INFO/PON; FilterMutectCalls marked
#       panel_of_normals. Without --pon: PB_POSTPON absent, 0 panel_of_normals.
#   C3  MUTECTCALLER wrote f1r2; LEARNORIENTATION ran and POSTPON got --ob-priors
#       (or neither, if the run used --mutect_orientation_filter false)
#   all POSTPON got --stats; filtered VCF + .tbi published
#
# Task work dirs are found from <outdir>/pipeline_info/trace.txt, which the
# pipeline OVERWRITES on every run (trace.overwrite = true) -- so this always
# checks the LATEST run in that outdir, cached tasks included. Run it from the
# launch directory or anywhere; work dirs in the trace are absolute.
#
# Every run appends one line to mutectcaller_verification_history.tsv (next to
# this script) so counts can be compared across parameter changes.
#
# bcftools: uses `bcftools` on PATH if present, otherwise BCFTOOLS_SIF via
# `singularity exec` (default below is the Fox image), binding the outdir and
# work dirs' real paths automatically.
#-------------------------------------------------------------------
set -o nounset
set -o pipefail

OUTDIR="${1:?usage: bash mutectcaller_verification_test.sh <outdir> (e.g. results_somatic_mt_parity)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY="${HISTORY:-${SCRIPT_DIR}/mutectcaller_verification_history.tsv}"
STRICT="${STRICT:-0}"
TOL_PCT="${TOL_PCT:-2}"   # +/- percent tolerance on count baselines

# ---- baselines: smoke-test TUMOR01/NORMAL01 + synthetic PON (pon_synth.vcf.gz) ----
EXP_RAW_NOPON="${EXP_RAW_NOPON:-4893}"     # MUTECTCALLER records, no --pon (gate N0)
EXP_RAW_PON="${EXP_RAW_PON:-3293}"         # MUTECTCALLER records, --pon      (gate N1)
EXP_PON_FLAGGED="${EXP_PON_FLAGGED:-2940}" # PB_POSTPON INFO/PON=1            (gate N2)
EXP_PON_FILTERED="${EXP_PON_FILTERED:-2940}" # FILTER contains panel_of_normals (expected ~= flagged)

TRACE="${OUTDIR}/pipeline_info/trace.txt"

## Update bcftools container path (if needed)
##    else: run `BCFTOOLS_SIF= <PATH>/bcftools-1.23--h3a4d415_0.sif bash ...  `
BCFTOOLS_SIF="${BCFTOOLS_SIF:-/projects/ec232/ngs/ngs_singularity/bcftools-1.23--h3a4d415_0.sif}"

n_fail=0; n_warn=0; n_skip=0
pass() { printf '  PASS  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; n_fail=$((n_fail+1)); }
warn() { printf '  WARN  %s\n' "$*"; n_warn=$((n_warn+1)); }
info() { printf '  INFO  %s\n' "$*"; }
skip() { printf '  SKIP  %s\n' "$*"; n_skip=$((n_skip+1)); }
h()    { echo; echo "=== $* ==="; }

[[ -s "$TRACE" ]] || { echo "ERROR: no trace file at $TRACE -- is '$OUTDIR' the pipeline's --outdir?"; exit 2; }

# ---- task work dir for a process, from the trace (last COMPLETED/CACHED row) ----
workdir_of() {
    awk -F'\t' -v p="$1" '
        NR==1 { for (i=1;i<=NF;i++) col[$i]=i; next }
        { proc=$col["process"]; sub(/.*:/, "", proc) }
        proc==p && ($col["status"]=="COMPLETED" || $col["status"]=="CACHED") { wd=$col["workdir"] }
        END { print wd }' "$TRACE"
}
status_of() {
    awk -F'\t' -v p="$1" '
        NR==1 { for (i=1;i<=NF;i++) col[$i]=i; next }
        { proc=$col["process"]; sub(/.*:/, "", proc) }
        proc==p { s=s (s?",":"") $col["status"] }
        END { print (s ? s : "absent") }' "$TRACE"
}

MC=$(workdir_of MUTECTCALLER)
PBP=$(workdir_of PB_POSTPON)
LO=$(workdir_of LEARNORIENTATION)
PP=$(workdir_of POSTPON)

# ---- bcftools: PATH, else container ----
if command -v bcftools >/dev/null 2>&1; then
    BCF=(bcftools)
elif command -v singularity >/dev/null 2>&1 && [[ -f "$BCFTOOLS_SIF" ]]; then
    binds=()
    for d in "$OUTDIR" "$MC" "$PBP" "$PP"; do
        [[ -n "$d" && -e "$d" ]] && binds+=(-B "$(dirname "$(realpath "$d")")")
    done
    # staged inputs are symlinks to their real location -- bind that too
    if [[ -n "$MC" && -f "$MC/.command.sh" ]]; then
        gr=$(grep -oP -- '--mutect-germline-resource \K\S+' "$MC/.command.sh" | head -1)
        [[ -n "$gr" && -e "$MC/$gr" ]] && binds+=(-B "$(dirname "$(realpath "$MC/$gr")")")
    fi
    BCF=(singularity exec "${binds[@]}" "$BCFTOOLS_SIF" bcftools)
else
    echo "ERROR: no bcftools on PATH and BCFTOOLS_SIF not usable ($BCFTOOLS_SIF)."; exit 2
fi

# count within +/- TOL_PCT of expected?
near() { awk -v a="$1" -v e="$2" -v t="$TOL_PCT" 'BEGIN { d=a-e; if (d<0) d=-d; exit !(e>0 ? d*100/e <= t : a==e) }'; }
count_check() {  # label actual expected
    if [[ "$2" =~ ^[0-9]+$ ]] && near "$2" "$3"; then pass "$1: $2 (baseline $3, +/-${TOL_PCT}%)"
    else warn "$1: $2 (baseline $3, +/-${TOL_PCT}%) -- intended? update the baseline if so"; fi
}
has_flag() { [[ -n "$1" && -f "$1/.command.sh" ]] && grep -q -- "$2" "$1/.command.sh"; }

echo "mutectcaller_verification_test  outdir=$OUTDIR  $(date '+%F %T')"
echo "git: $(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo n/a)$(git -C "$SCRIPT_DIR" diff --quiet 2>/dev/null || echo ' (dirty)')"
echo "bcftools: ${BCF[*]}"

h "0. Tasks in the latest run (trace.txt)"
for p in MUTECTCALLER PREPON PB_POSTPON LEARNORIENTATION POSTPON VCFQC; do
    printf '  %-18s %s\n' "$p" "$(status_of $p)"
done
[[ -n "$MC" && -d "$MC" ]] || { fail "MUTECTCALLER work dir not found (trace says: '$MC') -- work/ cleaned?"; exit 1; }
[[ -n "$PP" && -d "$PP" ]] || fail "POSTPON did not complete (or work dir missing) -- no filtered VCF"

RAW="$MC/$(cd "$MC" && ls *.mutect2.vcf.gz 2>/dev/null | head -1)"
PREFIX="$(basename "$RAW" .mutect2.vcf.gz)"
FINAL="${OUTDIR}/vcf/mutect2/${PREFIX}.mutect2.filtered.vcf.gz"
PON_RUN=0; has_flag "$MC" '--pon ' && PON_RUN=1
ORIENT_RUN=0; [[ -n "$LO" ]] && ORIENT_RUN=1
info "pair: $PREFIX   PON run: $([[ $PON_RUN == 1 ]] && echo yes || echo no)   orientation filter: $([[ $ORIENT_RUN == 1 ]] && echo yes || echo no)"

h "1. Outputs"
[[ -s "$RAW" ]]        && pass "raw Mutect2 VCF: $RAW"   || fail "raw Mutect2 VCF missing in $MC"
[[ -s "$FINAL" ]]      && pass "filtered VCF published: $FINAL" || fail "filtered VCF missing: $FINAL"
[[ -s "$FINAL.tbi" ]]  && pass "filtered VCF index (.tbi)" || fail "missing $FINAL.tbi"

h "C1. Germline resource"
has_flag "$MC" '--mutect-germline-resource' && pass "MUTECTCALLER has --mutect-germline-resource" \
                                            || fail "MUTECTCALLER .command.sh lacks --mutect-germline-resource"
GR_NAME=$(grep -oP -- '--mutect-germline-resource \K\S+' "$MC/.command.sh" 2>/dev/null | head -1)
GR_HAS_AF=NA
if [[ -n "$GR_NAME" && -e "$MC/$GR_NAME" ]]; then
    if "${BCF[@]}" view -h "$MC/$GR_NAME" 2>/dev/null | grep -q '^##INFO=<ID=AF,'; then GR_HAS_AF=1; else GR_HAS_AF=0; fi
fi
n_popaf=$("${BCF[@]}" query -f '%INFO/POPAF\n' "$RAW" 2>/dev/null | sort -u | wc -l)
if [[ "$GR_HAS_AF" == 0 ]]; then
    skip "germline resource $GR_NAME has no INFO/AF (wiring-only stand-in) -- POPAF check skipped ($n_popaf distinct value(s)); C1 is wired, not verified"
elif [[ "$n_popaf" -gt 1 ]]; then pass "POPAF varies: $n_popaf distinct values (resource has INFO/AF)"
else fail "POPAF has $n_popaf distinct value(s) although the germline resource has INFO/AF -- not applied?"; fi

h "C2. Panel of normals"
raw_n=$("${BCF[@]}" view -H "$RAW" | wc -l)
pon_filtered=$([[ -s "$FINAL" ]] && "${BCF[@]}" view -H -i 'FILTER~"panel_of_normals"' "$FINAL" | wc -l || echo NA)
if [[ $PON_RUN == 1 ]]; then
    pass "MUTECTCALLER has --pon"
    count_check "raw records with PON (suppression)" "$raw_n" "$EXP_RAW_PON"
    if [[ -n "$PBP" && -d "$PBP" ]]; then
        PBV="$PBP/${PREFIX}.mutect2.pon.vcf"
        if [[ -s "$PBV" ]]; then
            pbp_n=$("${BCF[@]}" view -H "$PBV" | wc -l)
            [[ "$pbp_n" == "$raw_n" ]] && pass "PB_POSTPON removed nothing ($pbp_n records)" \
                                       || warn "PB_POSTPON record count $pbp_n != raw $raw_n (postpon should only annotate)"
            flagged=$("${BCF[@]}" view -H -i 'INFO/PON=1' "$PBV" | wc -l)
            count_check "PB_POSTPON INFO/PON=1" "$flagged" "$EXP_PON_FLAGGED"
        else fail "PB_POSTPON output missing: $PBV"; fi
    else fail "PON run but PB_POSTPON did not complete -- INFO/PON never added"; fi
    count_check "filtered FILTER~panel_of_normals" "$pon_filtered" "$EXP_PON_FILTERED"
    [[ "$pon_filtered" =~ ^[0-9]+$ && "$pon_filtered" -gt 0 ]] || fail "no panel_of_normals filtering in the final VCF"
else
    info "no --pon in this run"
    count_check "raw records without PON" "$raw_n" "$EXP_RAW_NOPON"
    [[ -z "$PBP" ]] && pass "PB_POSTPON not run (correct without --pon)" || fail "PB_POSTPON ran without --pon"
    [[ "$pon_filtered" == 0 ]] && pass "0 panel_of_normals in final VCF" || warn "panel_of_normals=$pon_filtered without a PON"
fi

h "C3. Read-orientation filter"
has_flag "$MC" '--mutect-f1r2-tar-gz' && pass "MUTECTCALLER has --mutect-f1r2-tar-gz" \
                                      || fail "MUTECTCALLER .command.sh lacks --mutect-f1r2-tar-gz"
if [[ $ORIENT_RUN == 1 ]]; then
    ls "$LO"/*.read-orientation-model.tar.gz >/dev/null 2>&1 && pass "LEARNORIENTATION produced a model" \
                                                           || fail "LEARNORIENTATION model file missing in $LO"
    has_flag "$PP" '--ob-priors' && pass "POSTPON has --ob-priors" || fail "LEARNORIENTATION ran but POSTPON lacks --ob-priors"
else
    info "LEARNORIENTATION not in this run (--mutect_orientation_filter false?)"
    has_flag "$PP" '--ob-priors' && fail "POSTPON has --ob-priors without LEARNORIENTATION" || pass "no --ob-priors (consistent)"
fi
orient_n=$([[ -s "$FINAL" ]] && "${BCF[@]}" view -H -i 'FILTER~"orientation"' "$FINAL" | wc -l || echo NA)
info "FILTER~orientation records: $orient_n (any number is valid; record it to compare runs)"

h "Other wiring"
has_flag "$PP" '--stats ' && pass "POSTPON passes --stats explicitly" || fail "POSTPON lacks --stats"
pass_n=$([[ -s "$FINAL" ]] && "${BCF[@]}" view -H -f PASS "$FINAL" | wc -l || echo NA)
info "final PASS records: $pass_n"

# ---- history line ----
if [[ ! -s "$HISTORY" ]]; then
    printf 'date\tgit\toutdir\tpon\torientation\tgermline_af\tpopaf_distinct\traw\tpon_flagged\tpon_filtered\torientation_filtered\tpass\tfail\twarn\tskip\n' > "$HISTORY"
fi
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(date '+%F %T')" "$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo n/a)" "$OUTDIR" \
    "$PON_RUN" "$ORIENT_RUN" "$GR_HAS_AF" "$n_popaf" "$raw_n" "${flagged:-NA}" "$pon_filtered" "$orient_n" "$pass_n" "$n_fail" "$n_warn" "$n_skip" >> "$HISTORY"

echo
echo "RESULT: $n_fail FAIL, $n_warn WARN, $n_skip SKIP   (history: $HISTORY)"
if (( n_fail > 0 )) || { [[ "$STRICT" == 1 ]] && (( n_warn > 0 )); }; then exit 1; fi
exit 0
