# Results Giraffe vs FASTA ref

Jobs: `build_primary_ref_fox.sbatch` → 4237112 (4.1 min, 10.4 GiB peak), 
`diagnose_ref_check2_fox.sbatch` → 4237146 (4.3 min, 0.2 GiB peak). Both exit 0.
Logs: `giraffe_primary_ref-4237112.out`, `giraffe_check2_diag-4237146.out`.

| Question | Result | Hypothesis |
|---|---|---|
| Are the two source FASTAs the same file? | Same MD5 (`7ff13495…`), same size (3,249,912,778 B) | ***Same source FASTAs*** |
| Line widths | graph 80, both sources **100** | `vg paths` returned file with 80bp per seq, while `samtools faidx` returned files with 100bp (check notes below) |
| Base differences (graph vs each source) | `case_only=0 N_vs_IUPAC=94`, zero `N_vs_ACGT`, `ACGT_vs_N`| `vg autoindex` stores bases uppercase and writes non-ACGTN codes as `N` |
| Source ambiguity codes | B=2, K=8, M=8, R=26, S=4, W=13, Y=33 (sum 94) | every one became `N` in the graph |
| Where | 14 contigs (chr1, 2, 3, 6, 7, 9, 10, 12, 13, 16, 17, 21, 22, X) | |
| Impact | 0 DeepVariant / 0 HaplotypeCaller calls at the 94 sites, for giraffe **and** fq2bam | none |

## Notes

### Column length differences between index files

#### Giraffe index (`vg paths`)

```none
head Homo_sapiens_assembly38.primary.gbz.fa.fai
chr1    248956422       6       80      81
chr2    242193529       252068390       80      81
chr3    198295559       497289345       80      81
chr4    190214555       698063605       80      81
chr5    181538259       890655848       80      81
chr6    170805979       1074463342      80      81
chr7    159345973       1247404402      80      81
chr8    145138636       1408742206      80      81
chr9    138394717       1555695081      80      81
chr10   133797422       1695819739      80      81
```

#### `Samtools faidx`

```none
head Homo_sapiens_assembly38.fasta.fai
chr1    248956422       112     100     101
chr2    242193529       251446211       100     101
chr3    198295559       496061788       100     101
chr4    190214555       696340415       100     101
chr5    181538259       888457250       100     101
chr6    170805979       1071811004      100     101
chr7    159345973       1244325155      100     101
chr8    145138636       1405264700      100     101
chr9    138394717       1551854835      100     101
chr10   133797422       1691633613      100     101
```