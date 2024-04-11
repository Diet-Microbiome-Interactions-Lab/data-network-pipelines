#<center>Comprehensive Guide: Annotate.smk</center>
###<center> Purpose: Annotate genomes using a suite of methods</center>

##1.) Configuration Setup


####Step 1.1: Point to the location where your fasta (nucleotide) files are.  
The path is <u>relative</u> to this Snakemake file. For example, if you are in the directory: "MyAnalysis",  

```bash
. (MyAnalysis)
├── Annotate.smk
└── fasta_files
    ├── a.fasta
    ├── b.fasta
    └── c.fasta
```
The location of the fasta files are in the "fasta\_files" directory, so in the config.yaml file the key "contigs" should have a value of "fasta\_files". See below:

```
contigs: "fasta_files"
```
The extension of the files are ".fasta", so in the config.yaml file the key "extension" should have a value of "fasta". See below:  

```
extension: "fasta
```

#### Step 1.2: Point to the location of analyzed files.  
A few more configuration values need to be specified in order to tell the pipeline where to write output files. Default values <u>do not</u> need to be changed, but can be to customize your analysis.  

The first rule, <b>Reformat\_Fasta</b> takes in a fasta file and ensures that is is not corrupt and follows the rules of a standard fasta file and then renames all deflines from 1-N (N=number of sequences in file). The reason deflines are renamed is because some downstream analysis software does not play nice with spaces and odd characters in deflines and will throw untimely errors. Given the location of the input fasta files (through the config.yaml values), this rule outputs "clean, verified fasta files" to a location of your choice defined by the config key "verified_contigs".  

```
clean_contigs: "fasta_files_verified"
```
This step also renames the original fasta files to have the suffix "-VERIFIED" before the example. For example, a.fasta turns into a-VERIFIED.fasta.  

The next rule, <b>Create\_Database</b> takes the VERIFIED fasta files and turns them into a sqlite3 database via Anvi'o. The location of this file can be defined through the config key "contig\_db". See below:  

```
contigdb: "contig_dbs"
```
This creates a sqlite3 database file that is named from the input fasta file but with the extension of ".db". For example, fasta_files/a.fasta becomes ContigDBs/a.db  

The final config value to optionally define is "log_id", which defines the name of a directory where all log files will be written to. See below:  

```
log_id: "AnnotatingMAGs"
```

####Step 1.3: Add resource variables to config.yaml.  
To specify a base level of threads to use for the analysis, the config key "threads" and be changed. See below:  

```
threads: 8
```

#### Showcase of full config.yaml file:  
```
# File Specifications
contigs: "fasta_files"
extension: "fasta"
verified_contigs: "fasta_files_verified"
contig_db: "contig_dbs"


# Computing
threads: 80

# Logging
log_id: "AnnotatingMAGs"
```

<hr style="border:2px solid black">
##2.) Step-By Step Rule Guide

1.) Reformat\_Fasta  
<u>Description:</u> This rule takes in the raw nucleotide sequences and validates the sequence and renames deflines to avoid special characters.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-script-reformat-fasta)  
<u>Parameters:</u> fasta; -o (output); --simplify-names; --seq-type NT;  

2.) Create\_Database  
<u>Description:</u> This rule takes in the verified nucleotide sequence files and creates a sqlite3 database through Anvi'o.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-gen-contigs-database)  
<u>Parameters:</u> -o (output); -T (threads); --seq-type NT;

3.) Run\_HMMs  
<u>Description:</u> Run HMMs on the contigs database through Anvi'o.  
<u>Program(s) Used:</u>  Anvi'o ($anvi--run-hmms)  
<u>Parameters:</u> contigs db; -T (threads); --also-scan-trnas; --just-do-it;

4.) Run\_SCG_Taxonomy  
<u>Description:</u> Scan the contig databases for putative singe-copy genes (SCGs) as defined through Anvi'o. Next, given the taxonomic associations of the SCGs, estimate the total taxonomy of each contig database.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-run-scg-taxonomy; $anvi-estimate-scg-taxonomy)  
<u>Parameters:</u> contigs db; -T (threads); --metagenome-mode; --output-file;

5.) Run\_COGs 
<u>Description:</u> Annotate contigs database with COGs through Anvi'o.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-run-ncbi-cogs)  
<u>Parameters:</u> contigs db; -T (threads);

6.) Run\_KEGG  
<u>Description:</u> Annotate contigs database with KEGG through Anvi'o.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-run-kegg-kofams)  
<u>Parameters:</u> contigs db; -T (threads);

7.) Run\_PFam  
<u>Description:</u> Annotate contigs database with PFams through Anvi'o.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-run-pfams)  
<u>Parameters:</u> contigs db; -T (threads);


8.) Export\_FAA
<u>Description:</u> Export the predicted amino acid (FAA) hits per contig database. RAST and TigrFams are annotated using these FAA files instead of HMMs (as was the case with COGs, KEGG, and PFams).  
<u>Program(s) Used:</u>  Anvi'o ($anvi-get-sequences-for-gene-calls)  
<u>Parameters:</u> contigs db; -o (output); --get-aa-sequences;

9.) Export\_Gene\_Calls
<u>Description:</u> Export the gene calls file from the contigs database. This file is similar to a GFF file, mapping locations to each gene region. This file is necessary in order to create the final GFF3 file created from this pipeline.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-export-gene-calls)  
<u>Parameters:</u> contigs db; -o (output); --gene-caller prodigal;

10.) RAST\_Run  
<u>Description:</u> Given the faa file (from 8), external to anvi'o, annotate the FAA file with FigFams.  
<u>Program(s) Used:</u>  RAST ($svr_assign_using_figfams)  
<u>Parameters:</u> input; output;

11.) RAST\_Reformat  
<u>Description:</u> Given the output from (10), reformat the raw output from running FigFams into a format that anvi'o can accept back into the contigs database.  
<u>Program(s) Used:</u>  CUSTOM Python ($rast-table.py)  
<u>Parameters:</u> input; output;


12.) RAST\_Input  
<u>Description:</u> Input massaged RAST annotation data into the contigs db.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-import-functions)  
<u>Parameters:</u> input; output;

13.) TigrFam\_Run  
<u>Description:</u> Given the faa file (from 8), external to anvi'o, annotate the FAA file with TigrFams.  
<u>Program(s) Used:</u>  HMMER ($hmmsearch)  
<u>Parameters:</u> input; <b>database</b>; output; --tblout; --cpu;

14.) TigrFam\_Reformat  
<u>Description:</u> Given the output from (10), reformat the raw output from running TigrFams into a format that anvi'o can accept back into the contigs database.  
<u>Program(s) Used:</u>  CUSTOM Python ($tigrfam-table.py)  
<u>Parameters:</u> input; output; <b>tfam_roles (TFAM-Roles.txt)</b>;


15.) TigrFam\_Input  
<u>Description:</u> Input massaged TigrFam annotation data into the contigs db.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-import-functions)  
<u>Parameters:</u> input; output;

16.) Export\_Annotations  
<u>Description:</u> Export all annotations from anvi'o contig database.  
<u>Program(s) Used:</u>  Anvi'o ($anvi-export-functions)  
<u>Parameters:</u> input; output; --annotation-sources;  

17.) Reformat\_Gff3  
<u>Description:</u> Reformat output from (16) into a proper gff3 format.  
<u>Program(s) Used:</u>  CUSTOM Python ($combineFunctionsAndGeneCalls.py)  
<u>Parameters:</u> input (gene_calls); input (annotations); output;  
