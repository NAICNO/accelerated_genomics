Parabricks test dataset
========================

* Soure dataset - `https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz`
* Download testdataset
  
  ```bash
  wget -O parabricks_sample.tar.gz "https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz"
  ```

* Structure of the testdata directory

```bash
 parabricks_sample
 |-- Data
 |   |-- sample_1.fq.gz
 |   |-- sample_2.fq.gz
 |-- Ref
     |-- Homo_sapiens_assembly38.dict
     |-- Homo_sapiens_assembly38.fasta
     |-- Homo_sapiens_assembly38.fasta.amb
     |-- Homo_sapiens_assembly38.fasta.ann
     |-- Homo_sapiens_assembly38.fasta.bwt
     |-- Homo_sapiens_assembly38.fasta.fai
     |-- Homo_sapiens_assembly38.fasta.pac
     |-- Homo_sapiens_assembly38.fasta.sa
     |-- Homo_sapiens_assembly38.known_indels.vcf.gz
     `-- Homo_sapiens_assembly38.known_indels.vcf.gz.tbi

```

* Basic stats of the raw sequence files in `Data` direcory

```bash
 file               format  type    num_seqs        sum_len  min_len  avg_len  max_len
 sample_1.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
 sample_2.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
```
