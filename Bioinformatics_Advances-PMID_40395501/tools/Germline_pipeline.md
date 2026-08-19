# `NAIC Accelerated Genomics` Germline variant calling pipeline

Useres can implement GPU-based and CPU-based germline variant calling pipelines using `NAIC Accelerated Genomics` workflow suite.

## GPU-based Germline variant calling pipeline

```mermaid
graph TD;
   i1(Raw data - FASTQC) --> 1
   1(Parabricks FQ2BAM)
   1 --> 2
   2(Duplicates marked and sorted Alignment file)
   2 --> 3
   3(Parabricks APPLYBQSR)
   3 --> 4
   4(Duplicates marked & Recalibrated alignment file)
   4 --> 5
   5(Parabricks HaplotypeCaller)
   4 --> 6
   6(Parabricks DeepVariant)

   classDef highlight fill:#99ccff;
   classDef white fill:#ffffff;
   class 1,3,5,6 highlight;
```

### Parabricks versions

* All available versions: https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks/tags
* Version used in the pipeline (current Parabricks version used): `nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1`

***More information: [Parabricks page](Parabricks.md)***

## CPU-based Germline variant calling pipeline

```mermaid
graph TD;
   i1(Raw data - FASTQC) --> 1
   1(BWA and SAMTools)
   1 --> 2
   2(Sorted alignment file)
   2 --> 3
   3(GATK MarkDuplicates)
   3 --> 4
   4(Duplicates marked Alignment file)
   4 --> 5
   5(GATK BQSR)
   5 --> 6
   6(BaseQuality Recalibration Report)
   4 --> 7
   6 --> 7
   7(GATK ApplyBQSR)
   7 --> 8
   8(Duplicates marked & Recalibrated alignment file)
   8 --> 9
   9(GATK HaplotypeCaller)
   8 --> 10
   10(DeepVariant)

   classDef highlight fill:#99ccff;
   classDef white fill:#ffffff;
   class 1,3,5,7,9,10 highlight;
```

### CPU-based pipeline versions

* BWA: 0.7.17
* SAMTools: 1.18
* GATK: 4.3.0.0
* DeepVariant: 1.5.0
