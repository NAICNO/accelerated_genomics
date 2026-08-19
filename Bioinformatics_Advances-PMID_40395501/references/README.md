# Reference data

GRCh38/hg38 human reference genome

## Reference data on UiO ML-Nodes

UiO ML-nodes holds a copy of a indexed reference dataset at - `/storage/ngs/reference_data/GRCh38`

## FASTA file

`GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz` from [FTP site](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/)

A gzipped file that contains FASTA format sequences for the following:
1. chromosomes from the GRCh38 Primary Assembly unit.
   Note: the two PAR regions on chrY have been hard-masked with Ns.
   The chromosome Y sequence provided therefore has the same
   coordinates as the GenBank sequence but it is not identical to the
   GenBank sequence. Similarly, duplicate copies of centromeric arrays
   and WGS on chromosomes 5, 14, 19, 21 & 22 have been hard-masked
   with Ns (locations of the unmasked copies are given below).
2. mitochondrial genome from the GRCh38 non-nuclear assembly unit.
3. unlocalized scaffolds from the GRCh38 Primary Assembly unit.
4. unplaced scaffolds from the GRCh38 Primary Assembly unit.
5. Epstein-Barr virus (EBV) sequence
   Note: The EBV sequence is not part of the genome assembly but is 
   included in the analysis set as a sink for alignment of reads that
   are often present in sequencing samples.

*NOTES: https://lh3.github.io/2017/11/13/which-human-reference-genome-to-use*

## Index reference FASTA file

### SAMTOOLS index

`samtools faidx`: https://www.htslib.org/doc/samtools-faidx.html

### BWA-MEM index

`bwa index`: https://bio-bwa.sourceforge.net/bwa.shtml

### GATK CreateSequenceDictionary

`GATK CreateSequenceDictionary`: https://gatk.broadinstitute.org/hc/en-us/articles/360037422891-CreateSequenceDictionary-Picard-
