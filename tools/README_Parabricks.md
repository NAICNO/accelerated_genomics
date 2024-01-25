# Parabricks tools

**Follow the [link](https://docs.nvidia.com/clara/parabricks/v3.5/text/software_overview.html#software-tools-overview) to acceess the original source materials used to create table**

| Parabricks tool | Conventional tool | Details                |
| --------------- | ----------------- |----------------------- |
| FQ2BAM | BWA MEM; GATK SortSam, MarkDuplicates, BaseRecalibrator & BaseRecalibrator | Align, sort by co-ordinates & mark duplicates, optional bqsr on DNA-seq |
| BQSR | GATK BaseRecalibrator | Generate BQSR reports |
| APPLYBQSR | GATK ApplyBQSR | Apply a BQSR reports and create a new alignment file with recalibrated base-quality scores |
| HAPLOTYPECALLER | GATK ApplyBQSR & HaplotypeCaller | Apply base-quality recalibration using a BQSR report & calling germline variants |
| SAMTOOLS MPILEUP | Samtools | Generate *Samtools mpileup*  table |
| BCFTOOLS MPILEUP | Bcftools | Generate *Bcftools mpileup* table |
| BCFTOOLS CALL | Bcftools | Bcftools *call* variants using Bcftools pileup table |
| SOMATICSNIPER | Somatic-sniper | Call somatic variants *[Source GitHub repo is archived since 2020](https://github.com/genome/somatic-sniper)* |
| SOMATICSNIPER WORKFLOW | Somatic-sniper, bcftools, `snpfilter.pl`, `prepare_for_readcount.pl`, `bam-readcount`, `fpfilter.pl`, `highconfidence.pl` | Improved workflow to call somatic variants using bioinformatics tools and perl scripts|
| MANTA | Illumina-manta | Call structural variants and indels *[Source GitHub repo is archived since 2023](https://github.com/Illumina/manta)* |
| STRELKA | Illumina-strelka | Call somatic and germline variants (SNVs and InDels) |
| STRELKA WORKFLOW | Illumina- manta and strelka | Call structural variants, SNVs and InDels |
| MUTECTCALLER | GATK Mutect2 | Calling somatic variants using local haplotype information |
| DEEPVARIANT | Google deepvariant | Google's deep learning-based variant caller |
| CNVKIT | [CNVkit](https://cnvkit.readthedocs.io/en/stable/) | Detect and visualilze CNVs |
| BAMMETRICS | GATK CollectWGSMetrics | Collect coverage and performance metrics from WGS data |
| COLLECT MULTIPLE METRICS | GATK CollectMultipleMetrics| Collect a wide range of metrics from NGS data |
| DBSNP | NA | Annotate variants based on an input variant database |
| CNNSCOREVARIANTS | GATK CNNScoreVariants | Generate variant scores using a Convolutional Neural Network |
| VQSR | GATK VariantRecalibrator and ApplyVQSR | Build a recalibration model and apply a cutoff to filter variants. |
| TRIO COMBINE GVCF | GATK CombineGVCFs | Combine per-sample gVCF files into a multi-sample gVCF |
| GLNEXUS | [GLnexus project](https://github.com/dnanexus-rnd/GLnexus)| Scalable gVCF merging and joint variant calling for population sequencing projects. |
| INDEX GVCF | GATK IndexFeatureFile | Convert a gVCF To VCF. |
| GENOTYPEGVCF | GATK GenotypeGVCFs | Perform joint genotyping on one or more samples pre-called with HaplotypeCaller |
| RNA FQ2BAM | STAR, gatk SortSam, gatk MarkDuplicates | Align, sort by co-ordinates & mark duplicates, optional bqsr on RNA-seq |
| STAR-FUSION | STAR-Fusion | Detect candidate fusion transcripts. |

## Parabricks pipeline

| Pipeline  | Tools combined in the pipeline  |
| --------- | ------------------------------- |
| GERMLINE PIPELINE | BWA MEM; GATK SortSam, MarkDuplicates, BaseRecalibrator, ApplyBQSR and HaplotypeCaller |
| DEEPVARIANT GERMLINE PIPELINE | BWA MEM; GATK SortSam and MarkDuplicates, and deepvariant |
| HUMAN_PAR PIPELINE | Implement GATK4 germline variant calling best practices pipeline |
| SOMATIC PIPELINE | Implement GATK4 somatic variant calling best practices pipeline |
| RNA PIPELINE | Implement GATK RNAseq variant calling best practices |

## Parabricks Docker repository

* https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks/tags

## Parabricks compatible CPU software versions

[NVIDIA Parabricks v4.2.1](https://docs.nvidia.com/clara/parabricks/4.2.1/documentation/tooldocs/compatiblecpusoftwareversions.html)

| CPU Tool    | Version |
| ----------- | ------- |
| BWA         | 0.7.15  |
| Deepvariant | 1.5     |
| GATK        | 4.3.0.0 |
| STAR        | 2.7.2a  |
| STAR-Fusion | 1.7.0   |
