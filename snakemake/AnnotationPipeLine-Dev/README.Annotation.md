# Snakemake (8.4.*) Annotation Workflow
## Dane Deemer

### 1. Configuration
See ./config/config.yaml for full file
*Requirements*:
The following variables must be described in the config.yaml file in order for this workflow to run:
(File locations)
1. **raw_sequence**: [CRITICAL input file]: This should provide a path, relative to the snakefile, to the initial fastq files


### Notes:
- All anvi-setup-* scripts download by default to the location of the virtual environment! This means only 1 user needs to setup the database files.
- No files are created except in the conda environment under anvio/anvio/data/misc/<annotation_source>
  - Could have a smart-parser to see if the environment already has files downloaded...not sure if trying to re-download and not having the files in the snakemake-known output will cause an error or what not
- What is the EXPORT NAME for CAZYMES in anvi-export-functions?
- When you change the --runtime, it's actually multiplied for each rule if you have a group
  - For example, if --runtime=4 and group="main" has 4 jobs, it'll send off a SLURM job for 16 minutes