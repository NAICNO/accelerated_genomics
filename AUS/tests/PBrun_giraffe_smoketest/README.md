# PBrun Giraffe GPU Smoke Test

## Purpose

This test runs `pbrun giraffe` directly inside the Parabricks Singularity/Apptainer container on a real Fox cluster GPU.

It intentionally bypasses Nextflow and validates the underlying GPU tool before integrating Giraffe into the workflow.

The test confirms that:

- The Parabricks container starts successfully.
- A GPU is visible inside the container.
- The reference graph bundle is valid.
- Paired-end FASTQ input is accepted.
- `pbrun giraffe` produces a coordinate-sorted BAM.
- Duplicate metrics are generated.
- BAM indexing behavior is recorded.
- The BAM header contains the expected Giraffe program metadata.

## Test location

```text
AUS/tests/PBrun_giraffe_smoketest/
```

Expected files include:

```text
run_gpu_giraffe_smoketest_fox.sbatch
sample_normal_1.fastq.gz
sample_normal_2.fastq.gz
tiny_ref/
```

The `tiny_ref/` directory name is historical. It contains the real `Homo_sapiens_assembly38` reference graph bundle used by this test.

## Requirements

The test must be submitted on the Fox cluster with:

- Slurm
- An `accel` GPU node
- Account `ec232`
- Singularity or Apptainer
- NVIDIA GPU support
- The Parabricks 4.7.1 container
- SAMtools
- The reference graph bundle
- The paired FASTQ files

The default container path is:

```text
/projects/ec232/ngs/ngs_singularity/clara-parabricks_4.7.1-1.sif
```

## Required input files

The script expects the following files relative to the submission directory:

```text
sample_normal_1.fastq.gz
sample_normal_2.fastq.gz
tiny_ref/Homo_sapiens_assembly38*.gbz
tiny_ref/Homo_sapiens_assembly38*.dist
tiny_ref/Homo_sapiens_assembly38*.min
tiny_ref/Homo_sapiens_assembly38*.zipcodes
tiny_ref/Homo_sapiens_assembly38.primary.paths
```

The graph files are discovered by filename pattern. The paths file is currently configured explicitly as:

```text
tiny_ref/Homo_sapiens_assembly38.primary.paths
```

*Read: #107 and #108*

## Configuration

The main configuration values are defined near the top of:

```text
run_gpu_giraffe_smoketest_fox.sbatch
```

Important values include:

```bash
CONTAINER="/projects/ec232/ngs/ngs_singularity/clara-parabricks_4.7.1-1.sif"
PREFIX="Homo_sapiens_assembly38"
SAMPLE_ID="GIRAFFE_NORMAL01"
```

The Slurm request is:

```text
Partition: accel
GPU:       1
CPU:       16
Memory:    256G
Time:      10 minutes
Account:   ec232
```

Adjust the paths if the test is submitted from a different directory or if the cluster layout changes.

## Running the test

From the test directory, submit the job:

```bash
cd /Users/pubuduss/Developer/com/accelerated_genomics/AUS/tests/PBrun_giraffe_smoketest
sbatch run_gpu_giraffe_smoketest_fox.sbatch
```

Check the submitted job:

```bash
squeue -u "$USER"
```

The job writes Slurm output files using the job name and job ID:

```text
stest-gpu_giraffe-<jobid>.out
stest-gpu_giraffe-<jobid>.err
```

Follow the output while the job is running:

```bash
tail -f stest-gpu_giraffe-<jobid>.out
```

Check accounting after completion:

```bash
sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,TotalCPU
```

## Execution steps

The script performs these checks:

1. Determines the working directory.
2. Creates a temporary directory for Parabricks.
3. Locates the graph bundle files.
4. Verifies both paired FASTQ files exist.
5. Passes `CUDA_VISIBLE_DEVICES` into the container.
6. Runs `pbrun giraffe`.
7. Checks that the output BAM is non-empty.
8. Checks that duplicate metrics are non-empty.
9. Checks whether a `.bai` index is created automatically.
10. Inspects the BAM header with SAMtools.

The Giraffe command uses:

```text
--in-fq
--gbz-name
--dist-name
--minimizer-name
--zipcodes-name
--ref-paths
--out-bam
--out-duplicate-metrics
--sample
--read-group
--num-gpus 1
--tmp-dir
```

## Expected outputs

On success, the working directory should contain:

```text
GIRAFFE_NORMAL01.bam
GIRAFFE_NORMAL01.duplicate_metrics.txt
```

Depending on the Parabricks behavior, it may also contain:

```text
GIRAFFE_NORMAL01.bam.bai
```

The BAM must be non-empty, and the duplicate-metrics file must be non-empty.

The script reports whether the BAM index was created automatically. If no index is produced, the future Nextflow module will need an explicit indexing step, such as:

```bash
samtools index GIRAFFE_NORMAL01.bam
```

## Successful completion

A successful run ends with a summary similar to:

```text
pbrun giraffe completed successfully.
...
=== Done -- summary ===
```

The Slurm job should have a successful state:

```bash
sacct -j <jobid> --format=JobID,State
```

Expected state:

```text
COMPLETED
```

## Failure diagnosis

### Missing reference files

Typical message:

```text
ERROR: could not find a ... file under tiny_ref/
```

Check:

```bash
find tiny_ref -maxdepth 1 -type f -print
```

Verify that the graph filenames begin with:

```text
Homo_sapiens_assembly38
```

### Missing FASTQ files

Typical message:

```text
ERROR: expected ...sample_normal_1.fastq.gz and ...sample_normal_2.fastq.gz -- not found.
```

Check:

```bash
ls -lh sample_normal_1.fastq.gz sample_normal_2.fastq.gz
```

### GPU/container failure

Inspect the Slurm error file:

```bash
cat stest-gpu_giraffe-<jobid>.err
```

Confirm that the job received a GPU:

```bash
scontrol show job <jobid>
```

The script also prints the assigned `CUDA_VISIBLE_DEVICES` value.

### Output BAM missing or empty

Typical message:

```text
ERROR: ...GIRAFFE_NORMAL01.bam missing or empty.
```

Inspect the complete Parabricks output in the `.out` and `.err` files. Also check the temporary directory and available local scratch space.

### Duplicate metrics missing

Typical message:

```text
ERROR: ...duplicate_metrics.txt missing or empty
```

This indicates that the expected duplicate-marking output was not produced. Review the Parabricks log for the failure or verify the installed Parabricks version and command-line behavior.

### No Giraffe program record

The script warns if the BAM header does not contain a Giraffe-related `@PG` line. Inspect the header manually:

```bash
module load SAMtools
samtools view -H GIRAFFE_NORMAL01.bam
```

## Cleanup

The test can leave the following files:

```text
GIRAFFE_NORMAL01.bam
GIRAFFE_NORMAL01.bam.bai
GIRAFFE_NORMAL01.duplicate_metrics.txt
pbrun_tmp/
stest-gpu_giraffe-*.out
stest-gpu_giraffe-*.err
```

Remove them only after preserving any required test evidence:

```bash
rm -rf pbrun_tmp
rm -f GIRAFFE_NORMAL01.bam \
      GIRAFFE_NORMAL01.bam.bai \
      GIRAFFE_NORMAL01.duplicate_metrics.txt
```

## Evidence to record

For each successful smoke test, record:

- Slurm job ID
- Container path and version
- Hostname
- GPU allocation
- Elapsed time
- Maximum memory usage
- Total CPU time
- Output BAM size
- Duplicate-metrics file size
- Whether the `.bai` index was created
- Relevant BAM header lines

The accounting command is:

```bash
sacct -j <jobid> --format=JobID,Elapsed,MaxRSS,TotalCPU,State
```
