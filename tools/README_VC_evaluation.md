# Variant evaluation

Variant evaluation pipeline accepts VCF files from both CPU- and GPU-based pipelines and generates quality control matrices for each VCF file. Also, the pipeline performs concordance analysis on the two VCF files. The pipeline is designed to perform concordance analysis focusing on different target-regions. For example, in addition to the target-region file used for the exome capture kit, the pipeline accepts difficult-to-map and functional region files made available by PrecisionFDA [Truth Challenge](https://precision.fda.gov/challenges/truth/results).

```mermaid
graph TD;
   i1(Target-regions) --> 1
   i2(DIFFICULT2MAP regions) --> 1
   i3(Functional regions) --> 1
   1(Extract regions)
   1 --> 2
   1 --> 3
   1 --> 4
   2(Target-regions)
   3(DIFFICULT2MAP Target-regions)
   4(Functional Target-regions)
   2 --> 5
   3 --> 5
   4 --> 5
   i4(VCF CPU-pipeline) --> 5
   i5(VCF GPU-pipeline) --> 5
   5(Concordance analysis)
   5 --> 6
   5 --> 7
   5 --> 8
   6(Concordance: Target-regions)
   7(Concordance: DIFFICULT2MAP Target-regions)
   8(Concordance: Functional Target-regions)
   2 --> 9
   i4(VCF CPU-pipeline) --> 9
   i5(VCF GPU-pipeline) --> 9
   9(Generate QC matrices)
   9 --> 10
   9 --> 11
   10(VCF CPU-pipeline QC metrices)
   11(VCF GPU-pipeline QC metrices)

   classDef highlight fill:#99ccff;
   classDef white fill:#ffffff;
   class 1,2,3,4,5,6,7,8,9 highlight;
```

## Tools used in variant evaluation

* BEDTools
* GATK Concordance
* GATK VAREVAL

## Versions
