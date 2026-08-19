# Datasets used for the benchmark study

## Small test dataset (Parabricks dataset)

* Source dataset - `https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz`
* Structure of the test data directory

```bash
 parabricks_sample
 |-- [ 5.5G]  Data
 |   |-- [ 2.4G]  sample_1.fq.gz
 |   |-- [ 2.6G]  sample_2.fq.gz
 |-- [ 8.3G]  Ref
     |-- [ 407K]  Homo_sapiens_assembly38.dict
     |-- [ 3.0G]  Homo_sapiens_assembly38.fasta
     |-- [  20K]  Homo_sapiens_assembly38.fasta.amb
     |-- [ 445K]  Homo_sapiens_assembly38.fasta.ann
     |-- [ 3.0G]  Homo_sapiens_assembly38.fasta.bwt
     |-- [ 157K]  Homo_sapiens_assembly38.fasta.fai
     |-- [ 767M]  Homo_sapiens_assembly38.fasta.pac
     |-- [ 1.5G]  Homo_sapiens_assembly38.fasta.sa
     |-- [  59M]  Homo_sapiens_assembly38.known_indels.vcf.gz
     |-- [ 1.5M]  Homo_sapiens_assembly38.known_indels.vcf.gz.tbi
```

## The International Genome Sample Resource (IGSR): Whole Exome Sequence (WES) datasets

[IGSR](https://www.internationalgenome.org/) maintains and shares the human genetic variation resources built by the 1000 Genomes Project. Sequence data of trios within the pedigree (child, father and mother) from two populations were retrieved for the benchmark study.

* Population: Utah residents (CEPH) with Northern and Western European ancestry
* NA12878: Child
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/SRR1517906)
  * More information: [IGSR data portal](https://www.internationalgenome.org/data-portal/sample/NA12878)
* NA12891: Father
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/SRR098359)
  * More information: [IGSR data portal](https://www.internationalgenome.org/data-portal/sample/NA12891)
* NA12892: Mother
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/ERR034529)
  * More information: [IGSR data portal](https://www.internationalgenome.org/data-portal/sample/NA12892)


## Illumina Platinum Genomes: Whole Genome Sequence (WGS) datasets

Benchmark study was performed using WGS data of two trios used to generate ["Platinum variant catalogue"](https://www.illumina.com/platinumgenomes.html).

* Population: Utah residents (CEPH) with Northern and Western European ancestry
* NA12878: Child
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/ERR194147)
* NA12891: Father
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/ERR194160)
* NA12892: Mother
  * Source: [EBI SRA](https://www.ebi.ac.uk/ena/browser/view/ERR194161)

## Genome in a Bottle ([GIAB](https://www.nist.gov/programs-projects/genome-bottle)): Whole Exome Sequence (WES) datasets

* Population: Ashkenazim Jewish
* HG002
  * Source file: `HG002.GRCh38.2x250.bam` in [FTP](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG002_NA24385_sonNIST_Illumina_2x250bps/novoalign_bams/)
  * More information: [README](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG002_NA24385_son/NIST_Illumina_2x250bpsREADME_NIST_Illumina_pairedend_2x250_HG002.txt)
* HG003
  * Source file: `HG003.GRCh38.2x250.bam` in [FTP](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG003_NA24149_fatherNIST_Illumina_2x250bps/novoalign_bams/)
  * More information: [README](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG003_NA24149_father/NIST_Illumina_2x250bpsREADME_NIST_Illumina_pairedend_2x250_HG003.txt)
* HG004
  * Source file: `HG004.GRCh38.2x250.bam` in [FTP](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG004_NA24143_motherNIST_Illumina_2x250bps/novoalign_bams/)
  * More information: [README](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG004_NA24143_mother/NIST_Illumina_2x250bpsREADME_NIST_Illumina_pairedend_2x250_HG002.txt)
* Raw FASTQ reads are extracted by processing alignment files via `pbrun bam2fq` with `GRCh38` reference

## Genome in a Bottle ([GIAB](https://www.nist.gov/programs-projects/genome-bottle)): Whole Genome Sequence (WGS) datasets

* Population: Ashkenazim Jewish
* Source repository: [GIAB_DATA_INDECES](https://github.com/genome-in-a-bottle/giab_data_indexes/blob/master/AshkenazimTrio/alignment.index.AJtrio_OsloUniversityHospital_IlluminaExome_bwamem_GRCh37_11252015)
* HG002
  * Source file: `151002_7001448_0359_AC7F6GANXX_Sample_HG002-EEogPU_v02-KIT-Av5_AGATGTAC_L008.posiSrt.markDup.bam`
* HG003
  * Source file: `151002_7001448_0359_AC7F6GANXX_Sample_HG003-EEogPU_v02-KIT-Av5_TCTTCACA_L008.posiSrt.markDup.bam`
* HG004
  * Source file: `151002_7001448_0359_AC7F6GANXX_Sample_HG004-EEogPU_v02-KIT-Av5_CCGAAGTA_L008.posiSrt.markDup.bam`
* Raw FASTQ reads are extracted by processing alignment files via `pbrun bam2fq` with `hs37d5` reference

## Whole Exome Sequence (WES) datasets used for coverage-based benchmark analysis

* Alignment file `HG001.GRCh38_full_plus_hs38d1_analysis_set_minus_alts.300x.bam` was accessed via the [FTP site](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/NA12878/NIST_NA12878_HG001_HiSeq_300x/NHGRI_Illumina300X_novoalign_bams/) and extracted raw sequence datasets. FASTQ files of 300x sample was used to downsample ~150x, ~75x and ~35x using [`SeqKit sample`](https://bioinf.shenwei.me/seqkit/usage/#sample)
