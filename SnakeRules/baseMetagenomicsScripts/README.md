## README File Corresponding to 'base_metagenomics.sm'

Initial tree structure of working directory should follow this pattern:

- 📂 __MetagenomicsSkelton__
   - 📄 [README.md](README.md)
   - 📂 __config__
     - 📄 [cluster.json](config/cluster.json)
     - 📄 [config.yaml](config/config.yaml)
   - 📂 __input__
     - 📂 __Assembly__
       - 📄 [readme.txt](input/Assembly/readme.txt)
     - 📂 __Bat__
       - 📄 [readme.txt](input/Bat/readme.txt)
     - 📂 __Cat__
       - 📄 [readme.txt](input/Cat/readme.txt)
     - 📂 __Fastq__
       - 📄 [readme.txt](input/Fastq/readme.txt)
     - 📂 __GFF__
       - 📄 [readme.txt](input/GFF/readme.txt)
     - 📂 __OriginalBins__
       - 📄 [readme.txt](input/OriginalBins/readme.txt)
   - 📂 __workflow__
     - 📄 [binProcessing.smk](workflow/binProcessing.smk)
     - 📂 __envs__
       - 📄 [readme.txt](workflow/envs/readme.txt)
     - 📄 [readme.txt](workflow/readme.txt)
     - 📂 __scripts__
       - 📄 [aniContigRecycler.py](workflow/scripts/aniContigRecycler.py)
       - 📄 [appendBinsToANI.py](workflow/scripts/appendBinsToANI.py)
       - 📄 [filterSeqLength.py](workflow/scripts/filterSeqLength.py)
       - 📄 [getContigBinIdentifier.py](workflow/scripts/getContigBinIdentifier.py)
       - 📄 [splitFastaByEntry.py](workflow/scripts/splitFastaByEntry.py)
       - 📄 [taxonFilter.py](workflow/scripts/taxonFilter.py)

'''
Note: This general pattern may change depending on the analysis, but should follow a similar pattern.

## File Descriptions:
**0.) snakemake.smk**
- The main snakemake file that contains rules and local variables

**1.) cluster.json**

- File containing information to submit snakemake job to SLURM

**2.) config.yaml**

- This file contains project information and file path locations.
- Theoretically this should be the only file manipulated (not including the files inside of the input folder) that gets changed from analysis to analysis.

**3.) envs/{}.yaml**

- Files specifying the dependencies to be used by the pipeline

**4.) scripts/**

- Custom script files to be ran by the pipeline under specific rules

**5.) logs/*.log**
- Log files that are automatically created when running the pipeline

-

### Below is a snippet that lets SLURM know how to submit the jobs to the cluster:
-
<span style="color:red">*snakemake -s snakemake.smk --cluster-config config/cluster.json --cluster "sbatch -A {cluster.account} --mem {cluster.mem} -t {cluster.time} --cpus-per-task {cluster.cpus}"*</span>

The above parameters inside of the cluster.json file may need to be changed depending on the job.

<hr style="border:2px solid black"> </hr>

# Example 1: Running Snakemake

Given the tree structure above, first index the assembly file (W1.contigs.fasta):

1. Since all paths are relative to the snake.smk file, first enter the directory containing snake.smk
2. Add the following code to the empty snake.smk file:


<sub><sub><sub>Start of file</sub></sub></sub>
-
<span style="color:red">
Add some text here
</span>
-


The config file should look like this:

**3.) Execute a test run of the rule using the following command:**

- $ snakemake -s snake.smk -np  
*Note: the option -np results in a dry run, where no computations are performed but rules are checked for errors.*

**4.) Execute the rule by submitting it via SLURM:**  

- $ nohup snakemake -s snake.smk --use-conda -j 5 --cluster-config ../config/cluster.json --cluster "sbatch -A {cluster.account} --mem {cluster.mem} -t {cluster.time} --cpus-per-task {cluster.cpus}" &

*Note1: Yes, include the above " (quotes)*  
*Note2: By adding 'nohup' to the start and '&' to the end, this runs the job in the background and will allow the job to remain running even when ssh connection has been terminated.*

<span style="color:blue">This job will result in the following new files:  
- Multiple index files for the .FASTA assembly, located in the workflow/AssemblyIndex/ folder  
- A new log file located in the workflow/logs/ folder

-


```diff
- text in red
@@ text in purple @@
+ text in green
# text in gray
! text in orange
```

## Things that need addressing
- Accounting for paired-end reads non-extension suffix better
- Some way of determining the last time a rule's executable was verified
- Way of determining the versions of each tools (make sure they are the most up-to-date)
- 