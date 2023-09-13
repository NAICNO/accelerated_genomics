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
 |-- [ 5.5G]  Data
 |   |-- [ 2.4G]  sample_1.fq.gz
 |   `-- [ 2.6G]  sample_2.fq.gz
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
     `-- [ 1.5M]  Homo_sapiens_assembly38.known_indels.vcf.gz.tbi

```

* Basic stats of the raw sequence files in `Data` direcory

```bash
 file               format  type    num_seqs        sum_len  min_len  avg_len  max_len
 sample_1.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
 sample_2.fq.gz     FASTQ   DNA   26,658,919  3,065,775,685      115      115      115
```
