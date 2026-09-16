# Giraffe Reference Dataset Preparation

This SLURM pipeline prepares the index bundle and reference assets required for graph-based sequence alignment using `vg giraffe` and NVIDIA Clara Parabricks (`pbrun giraffe`).

- Use Parabricks test dataset and generate the indexes for `giraffe` runs

---

## Overview

Starting from a linear FASTA reference (`Homo_sapiens_assembly38.fasta`), this pipeline constructs:
1. **Graph & Seed Indexes:** `.gbz`, `.dist`, `.min`, and `.zipcodes`.
2. **Linear Projection Files:** Reference-path list (`.ref_paths.txt`) and a graph-extracted FASTA (`.ref.fa`) with corresponding Samtools `.fai` and `.dict` files.

---

## Expected Inputs & Directory Structure

Place your reference FASTA in the target reference directory before submitting:

project_root/
├── vg.sif                                  # Singularity container image for vg
├── tiny_ref/
│   └── Homo_sapiens_assembly38.fasta      # Input linear reference sequence
└── build_giraffe_index.sbatch             # SLURM submission script

Here is a comprehensive README.md documenting the indexing SLURM batch job:
# Giraffe Reference Dataset Preparation

This SLURM pipeline prepares the index bundle and reference assets required for graph-based sequence alignment using `vg giraffe` and NVIDIA Clara Parabricks (`pbrun giraffe`).

---


## Pipeline Execution Steps

### 1. Index Bundle Construction (vg autoindex)

- Workflow Detection: Different vg releases structure Giraffe targets differently. The script inspects vg autoindex --help and dynamically selects --workflow sr-giraffe (short-read) if supported, falling back to --workflow giraffe.
- Graph Synthesis: Translates the FASTA reference into a sequence graph. In the absence of a VCF, it constructs a linear sequence path without variant bubbles.
- Component Generation: ⚬ GBZ (.gbz): A compact graph structure combined with BWT-based haplotype/path indexes. ⚬ Snarl Distance Index (.dist): Calculates graph bubble topologies and minimum/maximum traversal distances. ⚬ Minimizer Index (.min): Indexes seed k-mers across graph paths for seed-and-extend read placement. ⚬ Zipcodes (.zipcodes): Pre-calculates distance query intervals across nodes for accelerated short-read seeding.

### 2. Discover and Validate Generated Indexes

- File Discovery: Dynamically locates the newly generated index files to accommodate variable prefix and naming outputs across vg versions.
- Fallback Zipcode Generation: Older versions using --workflow giraffe do not automatically create the .zipcodes structure. The script catches this omission and generates it using vg zipcodes -g <GBZ> -d <DIST>.
- Integrity Gate: Ensures all four indexes (.gbz, .dist, .min, .zipcodes) exist before executing subsequent steps.

### 3. Reference-Paths Extraction (--ref-paths)

- Queries the graph index via vg paths --list --xg <GBZ> to list all canonical sequence paths (e.g., chr1, chr2, ..., chrM).
- Why this is needed: pbrun giraffe uses this path list during linear projection to map multidimensional graph alignments (GAM/GAF) into standard linear chromosome coordinates in the resulting BAM/CRAM.

### 4. Graph-Derived Reference Sequence Extraction

- Extracts the sequence corresponding to the canonical paths out of the graph index using vg paths --extract-fasta.
- Parity Guarantee: Ensures the FASTA matches the coordinate offsets, chromosome identifiers, and base compositions stored inside the .gbz graph.
- Downstream Indexing: Generates sequence indices via: ⚬ samtools faidx: Creates .fai for random sequence lookup. ⚬ samtools dict: Generates a SAM sequence dictionary (.dict) containing @SQ headers and MD5 checksums for BAM generation and variant callers (e.g., GATK HaplotypeCaller).

## Output Files

Following a successful run, ${OUTPUT_DIR} contains:
| File Extension  | Description             | Purpose / Downstream Consumer                          |
| --------------- | ----------------------- | ------------------------------------------------------ |
| *.giraffe.gbz   | GBZ Graph + Path Index  | Primary graph reference for vg giraffe / pbrun giraffe |
| *.dist          | Snarl Distance Index    | Minimum-distance calculation between read seeds        |
| *.min           | Minimizer Index         | Graph seed matching during alignment                   |
| *.zipcodes      | Zipcode Index           | Short-read acceleration for distance lookups           |
| *.ref_paths.txt | List of reference paths | Linear projection target for --ref-paths               |
| *.fasta.ref.fa  | Graph-derived FASTA     | Reference file for linear BAM reconstruction           |
| *.ref.fa.fai    | Samtools FASTA index    | Random access index for FASTA                          |
| *.dict          | Sequence dictionary     | SAM header validation for downstream callers           |

## Submitting the Job

Submit the job to your SLURM scheduler:

```bash
sbatch build_giraffe_index.sbatch
```
