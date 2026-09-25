#!/bin/bash
#-------------------------------------------------------------------
# verify_tier2.sh -- Tier 2 checklist (docs/Giraffe_tier2_context.md section 5)
# as commands, run after a run_germline_tier2_fox.sbatch job finishes.
#
# Usage (from this directory, on a Fox login node):
#   bash verify_tier2.sh giraffe     # after the giraffe run
#   bash verify_tier2.sh fq2bam      # after the fq2bam baseline
#   bash verify_tier2.sh compare     # after both
#-------------------------------------------------------------------
set -o nounset
set -o pipefail

MODE="${1:?usage: bash verify_tier2.sh giraffe|fq2bam|compare}"
OUT=results_tier2
S=SAMPLE01
TIER1_BAM=/projects/ec232/ngs/analysis/AUS/girrfe_mapper/vg_mapping_exercises/GIRAFFE_NORMAL01.bam
GREF=/projects/ec232/ngs/analysis/AUS/girrfe_mapper/vg_mapping_exercises/tiny_ref/Homo_sapiens_assembly38.primary.gbz.fa

module purge >/dev/null 2>&1
module load SAMtools/1.17-GCC-12.2.0 >/dev/null 2>&1 || echo "NOTE: adjust the SAMtools module name"

h() { echo; echo "=== $* ==="; }
vcf_count() { [[ -s "$1" ]] && grep -vc '^#' "$1" || echo "MISSING $1"; }

if [[ "$MODE" == giraffe || "$MODE" == fq2bam ]]; then
    M="$MODE"; T="trace_params.${M}_fox.txt"

    h "1. every process COMPLETED (trace)"
    if [[ -s "$T" ]]; then
        awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)c[$i]=i; next}
                    {print $c["name"], $c["status"], $c["exit"], "realtime=" $c["realtime"], "peak_rss=" $c["peak_rss"], "attempt=" $c["attempt"]}' "$T"
    else echo "no $T -- did the head job finish?"; fi

    h "2. published tree"
    find "$OUT" -path "$OUT/pipeline_info" -prune -o -type f -print | grep -E "/(${M})/" | sort

    BAM="$OUT/bam/$M/$S/$S.bam"
    h "3. BAM header: @PG and @SQ"
    samtools view -H "$BAM" | grep '^@PG' | cut -c1-400
    echo "@SQ count: $(samtools view -H "$BAM" | grep -c '^@SQ')"

    h "4. .command.sh of the aligner task (flags actually sent to pbrun)"
    PROC=$( [[ "$M" == giraffe ]] && echo GIRAFFE || echo FQ2BAM )
    HASH=$(awk -F'\t' -v p="$PROC" 'NR==1{for(i=1;i<=NF;i++)c[$i]=i; next} $c["process"]==p && $c["status"]=="COMPLETED"{print $c["hash"]}' "$T" | tail -1)
    ls -d work/${HASH}* >/dev/null 2>&1 && cat work/${HASH}*/.command.sh || echo "work dir for $PROC ($HASH) not found"

    h "5. BQSR task: known-sites / contig messages (context doc 3b)"
    BH=$(awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)c[$i]=i; next} $c["process"]=="BQSR"{print $c["hash"]}' "$T" | tail -1)
    ls -d work/${BH}* >/dev/null 2>&1 && grep -i -E "contig|dictionar|error|warn" work/${BH}*/.command.{log,err} | head -20 || echo "BQSR work dir not found"

    h "6. variant counts (non-header lines)"
    echo "deepvariant:     $(vcf_count "$OUT/vcf/$M/deepvariant/$S.deepvariant.vcf")"
    echo "haplotypecaller: $(vcf_count "$OUT/vcf/$M/haplotypecaller/$S.haplotypecaller.vcf")"

    h "7. bcftools stats summary (VCFQC)"
    grep -H '^SN' "$OUT"/qc/vcf/$M/*/*.vcf_stats.txt | grep -E "number of (records|SNPs|indels)"

    h "8. flagstat"
    samtools flagstat "$BAM" | head -8

    if [[ "$M" == giraffe ]]; then
        h "9. giraffe-only: @SQ SN/LN == params.ref .fai (must be identical)"
        diff <(samtools view -H "$BAM" | awk -F'\t' '$1=="@SQ"{sub("SN:","",$2); sub("LN:","",$3); print $2"\t"$3}') \
             <(cut -f1,2 "$GREF.fai") && echo "OK: identical" || echo "MISMATCH (see diff above)"

        h "10. giraffe-only: flagstat vs Tier 1 BAM (same reads + index => should be identical)"
        diff <(samtools flagstat "$BAM") <(samtools flagstat "$TIER1_BAM") && echo "OK: identical to Tier 1" \
             || echo "differs from Tier 1 (expected only if read-group/sample naming changed counts -- it should not)"

        h "11. giraffe-only: duplicate metrics published"
        ls -la "$OUT/qc/bam/giraffe/$S/"
    fi
fi

if [[ "$MODE" == compare ]]; then
    h "giraffe vs fq2bam -- informational, not pass/fail (test graph has no haplotypes)"
    for c in deepvariant haplotypecaller; do
        for m in fq2bam giraffe; do
            V="$OUT/vcf/$m/$c/$S.$c.vcf"
            [[ -s "$V" ]] || { echo "$m $c: MISSING"; continue; }
            printf "%-8s %-16s all=%-8s chr21=%s\n" "$m" "$c" "$(grep -vc '^#' "$V")" \
                   "$(awk '!/^#/ && $1=="chr21"' "$V" | wc -l)"
        done
    done
fi
