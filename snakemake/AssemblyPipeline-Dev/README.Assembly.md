# Snakemake (8.4.*) Assembly Workflow
## Dane Deemer

### 1. Configuration
See ./config/config.yaml for full file
*Requirements*:
The following variables must be described in the config.yaml file in order for this workflow to run:
(File locations)
1. **raw_fqs**: [CRITICAL input file]: This should provide a path, relative to the snakefile, to the initial fastq files
2. **raw_fqs_ext**: This is the extension of the raw_fqs file. E.g., fastq.gz or fastq (do not include the initial file extension .)
3. **fastqc_out**: This should provide a path, relative to the snakefile, where you'd like the fastqc results to save to
4. **bbmerge_out**: This should provide a path, relative to the snakefile, where you'd like the bbmerge results to save to
5. **metaspades_out**: This should provide a path, relative to the snakefile, where you'd like the metaspades results to save to
6. **megahit_out**: This should provide a path, relative to the snakefile, where you'd like the megahit results to save to
7. **log_folder**: This is a directory you specify where all the job log files save to
(Parameters)
1. **threads**: How many threads the workflow should use (integer, 1-n, e.g., 20)
2. **ram_limit**: How much RAM to allocate for each job (integer, by default in Gigabytes, e.g., 16)

### 2. Jobs
1. **run_Fastqc**: Runs the program fastqc, which takes in reads (fastq files) and provides quality data on each one.
2. **run_BBMerge**: Runs bbmerge.sh (from the BBMap suite), which filters out adapters/other junk in the reads and combines them into 1 merged fasta file. This makes the assembly step much quicker and more reliable. This is crucial is paired-end (PE) fastq files have not been cleaned up.
3. **run_Spades**: Runs the assembler SPADES with the filtered, merged reads from the output of (2)
4. **run_Megahit**: Runs the assembler megahit with the filtered, merged reads from the output of (2)