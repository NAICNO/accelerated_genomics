# Parabricks GPU Variant Calling on TSD

- GPU-accelerated somatic and germline variant calling pipelines built on [NVIDIA Clara Parabricks](https://docs.nvidia.com/clara/parabricks/latest/index.html) (`pbrun`), written in Nextflow DSL2.
- Two independent pipelines live side by side in and share the same preprocessing modules and cluster config:

- **Somatic** (`somatic_main.nf`) -- tumor/normal pair -> Mutect2 + DeepSomatic
- **Germline** (`germline_workflow.nf`) -- single sample -> DeepVariant + HaplotypeCaller

## Layout

```none
├── configs                                               # config files of the pipeline
│   ├── PARABRICKS_FOX.conf                               #
│   ├── PARABRICKS_TSD.conf                               
│   └── singularity.conf                                  
├── DOCs
│   ├── checklists_&_runbooks                             # Template checklists and runbooks
│   ├── issues                                            # GitHub issue-specific docs
│   └── Scripts                                           # One-time scripts
├── germline_workflow.nf                                  # Germline workflow entry point
├── germline.config                                       # Germline params + profiles
├── modules                                               # NextFlow modules - Germline, Somatic and shared modules
├── README.md
├── somatic_main.nf                                       # Somatic workflow entry point
├── somatic.config                                        # Somatic params + profiles
└── tests                                                 # Tests - (smoke tests, regression tests)
```

## Workflows

### Somatic (`somatic_main.nf`)

```none
[Tumor FASTQ]  --> fq2bam --> [Tumor BAM]  --+
                                               +--> bqsr --> applybqsr --+--> mutectcaller --> postpon --> [Mutect2 VCF]
[Normal FASTQ] --> fq2bam --> [Normal BAM] --+                          |                  --> vcfqc
                                                                         +--> deepsomatic ------------------> [DeepSomatic VCF]
```

| Process | Tool | GPU | Purpose |
|---|---|---|---|
| `fq2bam` | `pbrun fq2bam` | yes | alignment, sorting, duplicate marking |
| `bqsr` | `pbrun bqsr` | yes | base quality score recalibration table |
| `applybqsr` | `pbrun applybqsr` | yes | apply the recal table |
| `prepon` | GATK `GetPileupSummaries` / `CalculateContamination` | no | contamination estimate for filtering |
| `mutectcaller` | `pbrun mutectcaller` | yes | somatic variant calling (Mutect2) |
| `postpon` | GATK `FilterMutectCalls` | no | final filtered Mutect2 VCF |
| `deepsomatic` | `pbrun deepsomatic` | yes | deep-learning somatic variant calling |
| `vcfqc` | `bcftools stats` | no | QC report on the raw Mutect2 VCF |

### Germline (`germline_workflow.nf`)

```none
[Sample FASTQ] --> fq2bam --> [BAM] --> bqsr --> applybqsr --> [Recalibrated BAM] --+--> deepvariant     --> vcfqc
                                                                                     +--> haplotypecaller --> vcfqc
```

| Process | Tool | GPU | Purpose |
|---|---|---|---|
| `fq2bam` | `pbrun fq2bam` | yes | alignment, sorting, duplicate marking |
| `bqsr` | `pbrun bqsr` | yes | base quality score recalibration table |
| `applybqsr` | `pbrun applybqsr` | yes | apply the recal table |
| `deepvariant` | `pbrun deepvariant` | yes | deep-learning germline variant calling |
| `haplotypecaller` | `pbrun haplotypecaller` | yes | germline variant calling (GATK HaplotypeCaller, GPU) |
| `vcfqc` | `bcftools stats` | no | QC report on each caller's VCF |

## Requirements

- **Nextflow** >= 24.04.0 on the submit node (Java - _Minimum Required Version: Java 11_; Tested with Java/25.36)
- **Apptainer/Singularity**
- **NVIDIA Clara Parabricks** container image
- **Other container images** for example,
  - GATK container image (somatic workflow only -- `prepon`/`postpon`)
  - bcftools container image (both workflows -- `vcfqc`)
- **Reference data**

## Installation / setup

1. Clone/Copy this repo into the project area
2. Get the container images
3. Edit `configs/PARABRICKS_<>.conf` and replace every `pXX` placeholder with your actual TSD project number:
   - `params.containerPath`
   - `clusterOptions` (both the top-level default and the `gpu_process` label block, `--account=pXX`)
4. Verify the GPU-specific settings against current TSD/FOX Slurm documentation before running at scale
   - `--partition=accel --gres=gpu:1` in the `gpu_process` label block
   - the `--nv` flag in `apptainer.runOptions`
   - the `-B /cluster,/gpfs` bind mounts, which should match your project's actual storage layout
5. Verify `pbrun` flag names against the Parabricks version
6. Prepare reference data

## How to run

Both workflows use plain `--param` flags (no samplesheet) for a single sample or tumor/normal pair per run, and both need their config passed explicitly with `-c` since neither file is named `nextflow.config`.

### Somatic

```bash
nextflow run somatic_main.nf -c somatic.config -profile singularity,tsd \
  --tumor_id  TUMOR01  --tumor_fastq_1  /path/T_R1.fastq.gz  --tumor_fastq_2  /path/T_R2.fastq.gz \
  --normal_id NORMAL01 --normal_fastq_1 /path/N_R1.fastq.gz --normal_fastq_2 /path/N_R2.fastq.gz \
  --ref /path/reference.fa \
  --known_sites /path/dbsnp.vcf.gz,/path/mills.vcf.gz \
  --germline_resource /path/gnomad.vcf.gz \
  --pon /path/panel_of_normals.vcf.gz \
  --parabricks_container file:///cluster/p/pXX/cluster/NGS/images/clara-parabricks_4.4.0-1.sif \
  --gatk_container       file:///cluster/p/pXX/cluster/NGS/images/gatk_4.5.0.0.sif \
  --bcftools_container   file:///cluster/p/pXX/cluster/NGS/images/bcftools_1.20.sif
```

**Run with `-params-file`:**

```bash
nextflow run somatic_main.nf -c somatic.config -profile singularity,tsd -params-file params.yaml
```

- `--pon` is optional; omit it to run Mutect2 without a panel of normals.
- Required params: `tumor_id`, `tumor_fastq_1`, `tumor_fastq_2`, `normal_id`, `normal_fastq_1`, `normal_fastq_2`, `ref`, `known_sites`, `germline_resource`, `parabricks_container`, `gatk_container`, `bcftools_container`

**Outputs land under `results/`** (override with `--outdir`):

```none
results/
├── bam/<sample_id>/                  # fq2bam output
├── bam_recal/<sample_id>/            # applybqsr output
├── vcf/mutect2/                      # postpon output (final filtered Mutect2 VCF)
├── vcf/deepsomatic/                  # deepsomatic output
└── qc/vcf/                           # vcfqc bcftools stats report
```

### Germline

```bash
nextflow run germline_workflow.nf -c germline.config -profile tsd \
  --sample_id SAMPLE01 --fastq_1 /path/S_R1.fastq.gz --fastq_2 /path/S_R2.fastq.gz \
  --ref /path/reference.fa \
  --known_sites /path/dbsnp.vcf.gz,/path/mills.vcf.gz \
  --parabricks_container file:///cluster/p/pXX/cluster/NGS/images/clara-parabricks_4.4.0-1.sif \
  --bcftools_container   file:///cluster/p/pXX/cluster/NGS/images/bcftools_1.20.sif
```

**Run with `-params-file`:**

```bash
nextflow run germline_workflow.nf -c germline.config -profile singularity,tsd -params-file params.yaml
```


- Optional params: `--deepvariant_mode` (`wgs` | `wes` | `ont`, default `wgs`), `--emit_gvcf` (default `false`, set `true` to have `haplotypecaller` emit a GVCF).
- Required params: `sample_id`, `fastq_1`, `fastq_2`, `ref`, `known_sites`, `parabricks_container`, `bcftools_container`.

**Outputs land under `results/`** (override with `--outdir`):

```none
results/
├── bam/<sample_id>/                  # fq2bam output
├── bam_recal/<sample_id>/            # applybqsr output
├── vcf/deepvariant/                  # deepvariant output
├── vcf/haplotypecaller/              # haplotypecaller output
└── qc/vcf/<caller>/                  # vcfqc bcftools stats reports
```

## Configuration reference

| File | Role |
|---|---|
| `somatic.config` / `germline.config` | workflow-specific params + `tsd` profile |
| `configs/PARABRICKS_<>.conf` | shared Slurm executor, Apptainer/GPU settings, per-process resource tuning (`withName`), included via `-profile < tsd \| fox>` |

- Both workflows define a `leaf_process` and `gpu_process` labels
  - `leaf_process`: retry once, then ignore on second failure
  - `gpu_process`: GPU partition, `--gres`, `accelerator` directive -- used by every `pbrun` step in `configs/PARABRICKS_TSD.conf`.
- *Any new caller module should carry `label 'gpu_process'` if it's a `pbrun` tool, and get a matching `withName:<PROCESS>` block in `configs/PARABRICKS_TSD.conf` for cpu/time tuning*
