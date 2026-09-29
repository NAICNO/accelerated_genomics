#!/usr/bin/env python3
"""
compare_fasta_bases.py GRAPH_FA SOURCE_FA OUT_PREFIX

Every differing base is put in one class:
  case_only        same base, different case (soft-masking)            -> harmless
  N_vs_IUPAC       graph N, source ambiguity code (M,R,Y,K,S,W,B,D,H,V) -> expected vg behaviour
  N_vs_ACGT        graph N, source a real base                          -> NOT expected
  ACGT_vs_N        graph real base, source N                            -> NOT expected
  substitution     both real bases, different                           -> NOT expected
  other            anything else                                        -> NOT expected

Writes:
  OUT_PREFIX.summary.tsv    per-contig counts per class
  OUT_PREFIX.diffs.tsv      contig, 1-based pos, graph base, source base, class
                            (all non-case differences, capped at 200,000 rows)
  OUT_PREFIX.diffs.bed      same positions as BED (for bcftools/samtools -R)
and prints totals, the source's non-ACGTN composition, and a verdict line.
"""
import sys
from collections import Counter, defaultdict

IUPAC = set("MRYKSWBDHVmrykswbdhv")
ACGT = set("ACGTacgt")
CAP = 200_000


def records(path):
    """Yield (name, iterator over sequence lines) without loading a contig."""
    fh = open(path, "r")
    line = fh.readline()
    while line:
        if not line.startswith(">"):
            raise SystemExit(f"{path}: expected header, got {line[:40]!r}")
        name = line[1:].split()[0]
        lines = []

        def seq_lines():
            nonlocal line
            while True:
                line = fh.readline()
                if not line or line.startswith(">"):
                    return
                yield line.rstrip("\n")

        yield name, seq_lines()


BLOCK = 1 << 20   # 1 Mbp comparison blocks, independent of FASTA line width


def chunks(lines, width_counter):
    """Re-chunk a record's sequence lines into BLOCK-size strings (last may be
    shorter). Records the line widths seen, so the report can show the layout."""
    buf = []
    n = 0
    for ln in lines:
        width_counter[len(ln)] += 1
        buf.append(ln)
        n += len(ln)
        if n >= BLOCK:
            joined = "".join(buf)
            while len(joined) >= BLOCK:
                yield joined[:BLOCK]
                joined = joined[BLOCK:]
            buf = [joined] if joined else []
            n = len(joined)
    if n:
        yield "".join(buf)


def classify(g, s):
    if g.upper() == s.upper():
        return "case_only"
    G, S = g.upper(), s.upper()
    if G == "N" and S in IUPAC:
        return "N_vs_IUPAC"
    if G == "N" and S in ACGT:
        return "N_vs_ACGT"
    if G in ACGT and S == "N":
        return "ACGT_vs_N"
    if G in ACGT and S in ACGT:
        return "substitution"
    return "other"


def main(graph_fa, source_fa, out):
    per_contig = defaultdict(Counter)
    src_comp = Counter()
    ndiff_rows = 0
    diffs = open(out + ".diffs.tsv", "w")
    bed = open(out + ".diffs.bed", "w")
    diffs.write("contig\tpos\tgraph\tsource\tclass\n")

    widths = {}
    for (gname, glines), (sname, slines) in zip(records(graph_fa), records(source_fa)):
        if gname != sname:
            raise SystemExit(f"contig order differs: graph {gname} vs source {sname}")
        gw, sw = Counter(), Counter()
        gc, sc = chunks(glines, gw), chunks(slines, sw)
        pos = glen = slen = 0
        while True:
            gb, sb = next(gc, None), next(sc, None)
            if gb is None and sb is None:
                break
            glen += len(gb or ""); slen += len(sb or "")
            if gb is None or sb is None or len(gb) != len(sb):
                # contig lengths differ: drain both to report true lengths
                glen += sum(len(x) for x in gc); slen += sum(len(x) for x in sc)
                raise SystemExit(f"{gname}: contig length differs (graph {glen} vs source {slen})")
            if gb != sb:
                for i, (g, s) in enumerate(zip(gb, sb)):
                    if g != s:
                        c = classify(g, s)
                        per_contig[gname][c] += 1
                        if c != "case_only" and ndiff_rows < CAP:
                            diffs.write(f"{gname}\t{pos + i + 1}\t{g}\t{s}\t{c}\n")
                            bed.write(f"{gname}\t{pos + i}\t{pos + i + 1}\n")
                            ndiff_rows += 1
            for ch in set(sb):
                if ch not in "ACGTNacgtn":
                    src_comp[ch.upper()] += sb.count(ch)
            pos += len(gb)
        per_contig[gname]["_length"] = glen
        widths[gname] = (gw.most_common(1)[0][0] if gw else 0, sw.most_common(1)[0][0] if sw else 0)

    diffs.close(); bed.close()

    classes = ["case_only", "N_vs_IUPAC", "N_vs_ACGT", "ACGT_vs_N", "substitution", "other"]
    with open(out + ".summary.tsv", "w") as fh:
        fh.write("contig\tlength\t" + "\t".join(classes) + "\n")
        for c, cnt in per_contig.items():
            fh.write(f"{c}\t{cnt['_length']}\t" + "\t".join(str(cnt[k]) for k in classes) + "\n")

    tot = Counter()
    for cnt in per_contig.values():
        for k in classes:
            tot[k] += cnt[k]
    lw = Counter(widths.values())
    print("LINE WIDTH (graph, source) per contig: " +
          ", ".join(f"{g}/{s} x{n}" for (g, s), n in lw.most_common()) +
          ("   <- different wrapping: a byte-level cmp would report DIFFER even for identical sequence"
           if any(g != s for g, s in widths.values()) else ""))
    print("TOTALS " + "  ".join(f"{k}={tot[k]}" for k in classes))
    print("SOURCE non-ACGTN bases (uppercased): " +
          (", ".join(f"{k}={v}" for k, v in sorted(src_comp.items())) or "none"))
    affected = [c for c, cnt in per_contig.items() if any(cnt[k] for k in classes[1:])]
    print("CONTIGS with non-case differences: " + (", ".join(affected) or "none"))

    bad = tot["N_vs_ACGT"] + tot["ACGT_vs_N"] + tot["substitution"] + tot["other"]
    if bad == 0 and tot["N_vs_IUPAC"] == 0:
        verdict = "IDENTICAL apart from case" if tot["case_only"] else "IDENTICAL"
    elif bad == 0:
        verdict = (f"ONLY IUPAC->N ({tot['N_vs_IUPAC']} sites) -- expected vg behaviour, "
                   f"harmless for bqsr/callers")
    else:
        verdict = f"REAL DIFFERENCES ({bad} sites not explained by case or IUPAC) -- investigate"
    print("VERDICT " + verdict)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    main(*sys.argv[1:])
