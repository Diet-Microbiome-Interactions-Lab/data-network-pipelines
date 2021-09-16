'''
Dane note: 16Sep21
Authors: Dane Deemer
Purpose: Snakemake pipeline that takes fastq DNA reads and bins
using a reference assembly 
Input: 
- Samples 
- Index (sample identifiers)
- Threads 
- Threshold
- Readsize

results:
- readsize
- threshold
- maxbin_abunds
- refinem_bams
'''
configfile: "../config/config.yaml"


rule all:
    input:
        expand("AssemblyIndex/{index}.1.bt2", index=config['index']),
        expand("Bam/Original/{sample}.sorted.bam.bai", sample=config['samples']),
        expand("Bam/{sample}.{processing}.sorted.bam", sample=config['samples'], processing=config['processing']),
        expand("CheckM/{binner}.{processing}/lineage.ms", binner=config['binner'], processing=config['processing'])


# ~~~~~~~~~~ STEP 0: Essentials ~~~~~~~~~~ #
# [Fastq QC/Trimming - Assembly Indexing - Alignment - Bam Sorting - Bam Indexing]

rule FastQC_Exec:
    input:
        read_pairs = expand("../input/Fastq/{{samples}}_{num}.fastq", num=["R1","R2"])
    params:
        threads=config["threads"]
    conda:
        "envs/fastqc.yaml"
    output:
        #directory=directory("FastqFiltered")
        out_alt=directory("FastQC/{sample}")
    #log:
        #"logs/filter_fastq.{samples}_{num}.log"
    shell:
        """
        mkdir {output.directory}
        fastqc -t {params} --outdir {output.directory} {input.read_pairs}
        """

rule Trimmomatic_Exec:
    input:
        read_pairs=expand("../input/Fastq/{{samples}}_{num}.fastq", num=["R1","R2"])
    params:
        threads=config["threads"]
    output:
        processed_read_pairs=expand("Fastq-Trimmed/{{samples}}-{tval}_R1.fastq", tval=["Trimmed", "Untrimmed"])
    shell:
        """
        trimmomatic PE {input.read_pairs} {output.processed_read_pairs} SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:NexteraPE-PE.fa:2:40:15
        """


# Index the assembly (or any fasta file)
# rule run_bowtie2_index:
rule Bowtie2Index_Exec:
    input:
        #needed=directory("FastqFiltered"), # Don't necessarily need this. Could index without fastQC
        assembly="../input/Assembly/{index}.fasta"
    params:
        threads=config["threads"],
        index="AssemblyIndex/{index}"
    conda:
        "envs/alignment.yaml"
    output:
        "AssemblyIndex/{index}.1.bt2"
    log:
        "logs/assemblyIndexing.{index}.log"
    shell:
        "bowtie2-build -f --threads {params.threads} {input.assembly} {params.index} >> {log}"

# Align fastq files to indexed assembly from above rule
rule Bowtie2Alignment_Exec:
    input:
        reads=expand("../input/Fastq/{{sample}}_{num}.fastq", num=["R1","R2"]),
        i=f"AssemblyIndex/{config['index']}.1.bt2"
    params:
        index=f"AssemblyIndex/{config['index']}",
        threads=config['threads']
    conda:
        "envs/alignment.yaml"
    output:
        "Bam/{sample}.bam"
    log:
        "logs/bowtie2Alignment.{sample}.log"
    shell:
        "(bowtie2 --threads {params.threads} -x {params.index} -1 {input.reads[0]} -2 {input.reads[1]} | samtools view -b -o {output}) &> {log}"

# Sort bam file created from above rule
rule SamToolsSort_Exec:
    input:
        "Bam/{sample}.bam"
    params:
        prefix="Bam/pref.{sample}",
        threads=config['threads']
    conda:
        "envs/alignment.yaml"
    output:
        "Bam/{sample}.original.sorted.bam"
    log:
        "logs/samtoolsSort.{sample}.log"
    shell:
        "samtools sort -@{params.threads} -T {params.prefix} -o {output} {input} &> {log}"

# bam_indexing: Index the bam file (required for downstream programs)
rule SamToolsIndex_Exec:
    input:
        "Bam/{sample}.original.sorted.bam"
    conda:
        "envs/alignment.yaml"
    output:
        "Bam/{sample}.original.sorted.bam.bai"
    log:
        "logs/samtoolsIndex.{sample}.log"
    shell:
        "samtools index -@20 {input} &> {log}"


# ~~~~~~~~~~ STEP 1: General Processing ~~~~~~~~~~ #
# [Bam Filtering - Calculating Coverage - Abundance Filter - Abundance File Merge]

# Filter BAM files to only contain reads mapping above a certain threshold of percent identity.
rule FilterBams_Script:
    input:
        "Bam/{sample}.original.sorted.bam"
    params:
        readsize=config['readsize'],
        threshold=config['threshold']
    conda:
        "envs/alignment.yaml"
    output:
        "Bam/{sample}.{processing}.sorted.bam"
    log:
        "logs/bamFiltering.{sample}.{processing}.log"
    shell:
        "(samtools view -h {input} | python scripts/sam_threshold_filter.py -s {params.readsize} -t {params.threshold} | samtools view -b -o {output} && samtools index -@20 {output}) &> {log}"

# Calculate coverage stats per contig
rule BBMapCoverage_Exec:
    input:
        "Bam/{sample}.{processing}.sorted.bam"
    conda:
        "envs/bbmap.yaml"
    output:
        "Abundances/{sample}.{processing}.coverage.txt"
    log:
        "logs/bbmap-abunds.{sample}.{processing}.log"
    shell:
        "pileup.sh in={input} out={output} &> {log}"

rule FormatAbundanceBBMap_Shell:
    input:
        "Abundances/{sample}.{processing}.coverage.txt"
    output:
        "Abundances/{sample}.{processing}.abundance.txt"
    shell:
        "cut -f 1,5 {input} | grep -v '^#' > {output}"

rule AppendAbundanceList_Script:
    input:
        expand("Abundances/{sample}.{{processing}}.abundance.txt", sample=config["samples"])
    output:
        "Abundances/abundance_list.{processing}.txt"
    script:
        "scripts/make_abund_list.py"


# Contig binning

rule Maxbin2Binning_Exec:
    input:
        abund="Abundances/abundance_list.{processing}.txt",
        scaff=expand("../input/Assembly/{index}.fasta", index=config['index'])
    params:
        pref=directory("Maxbin/{processing}"),
        threads=config["threads"]
    conda:
        "envs/maxbin.yaml"
    output:
        "Maxbin/{processing}/bins.summary"
    #log:
        #log="logs/maxbin2_{processing}_.log"
    shell:
        """
        run_MaxBin.pl -contig {input.scaff} -out {params.pref}/bins -abund_list {input.abund}
        """

# Metabat create depth file 
rule CreateDepthForMetabat_Exec:
    input:
        directory=directory("Maxbin"),
        bam=expand("Bam/{sample}.{{processing}}.sorted.bam", sample=config['samples'])
    conda:
        "envs/metabat2.yaml"
    output:
        "Metabat/depth.{processing}.txt"
    shell:
        """
        jgi_summarize_bam_contig_depths --outputDepth {output} {input.bam}
        """

# Metabat create bins
rule Metabat2Binning_Exec:
    input:
        depth="Metabat/depth.{processing}.txt"
    conda:
        "envs/metabat2.yaml"
    params:
        pref="Metabat/{processing}/bin",
        contig=expand("../input/Assembly/{index}.fasta", index=config["index"])
    output:
        directory("Metabat/{processing}")
    #log:
    #    "logs/assemblyIndexing.{index}.log"
    shell:
        """
        mkdir {output}
        metabat2 -i {params.contig} -a {input.depth} -o {params.pref}
        """

# Concoct create index 
rule CreateBedForConcoct_Exec:
    input:
        metabat=directory("Metabat/{processing}"),
        concoct=expand("../input/Assembly/{index}.fasta", index=config["index"])
    params:
         fasta="Concoct/{index}_10k.fasta"
    conda:
        "envs/concoct.yaml"
    output:
        bed="Concoct/{index}_10k.bed"
    shell:
        "cut_up_fasta.py {input.concoct} -c 10000 -o 0 --merge_last -b {output.bed} > {params.fasta}"

#Make a coverage table using bam files
rule CreateCoverageTableConcoct_Exec:
    input:
        bed=expand("Concoct/{index}_10k.bed", index=config['index'])
    params:
        bam=expand("Bam/{sample}.{{processing}}.sorted.bam", sample=config['samples'])
    conda:
        "envs/concoct.yaml"
    output:
        "Concoct/coverage_table.{processing}.tsv"
    #log:
    #    "logs/assemblyIndexing.{index}.log"
    shell:
        "concoct_coverage_table.py {input} {params.bam} > {output}"

#Run concoct
rule ConcoctBinning_Exec:
    input:
        coverage="Concoct/coverage_table.{processing}.tsv"
    conda:
        "envs/concoct.yaml"
    params:
        directory="Concoct/{processing}",
        fasta=expand("Concoct/{index}_10k.fasta", index=config['index'])
    output:
        clustering="Concoct/{processing}/clustering_gt1000.csv"
    #log:
    #    "logs/assemblyIndexing.{index}.log"
    shell:
        "concoct --composition_file {params.fasta} --coverage_file {input.coverage} -b {params.directory} --threads 20"

#Merge subcontig clustering into original contig clustering:
rule merge_concoct:
    input:
        clustering="Concoct/{processing}/clustering_gt1000.csv"
    conda:
        "envs/concoct.yaml"
    output:
        "Concoct/{processing}/clustering_merged.csv"
    #log:
    #    "logs/assemblyIndexing.{index}.log"
    shell:
        "merge_cutup_clustering.py {input.clustering} > {output}"        

#Extract bins as individual FASTA:
rule extract_concoct:
    input:
        merged="Concoct/{processing}/clustering_merged.csv"
    params:
        assembly=expand("../input/Assembly/{index}.fasta", index=config["index"]),
        directory="Concoct/{processing}"
    conda:
        "envs/concoct.yaml"
    output:
        directory("Concoct/{processing}/0.fa")
    #log:
    #    "logs/assemblyIndexing.{index}.log"
    shell:
        """
        extract_fasta_bins.py {params.assembly} {input.merged} --output_path {params.directory}
        """        

# Estimate completion and contamination for original binning

rule CheckmQC_Exec:
    input:
        "{binner}/{processing}"
    conda:
        "envs/checkm.yaml"
    params:
        threads=config['threads'],
        out="CheckM/{binner}.{processing}/"
    output:
        "CheckM/{binner}.{processing}/lineage.ms"
    log:
        "logs/checkm_{binner}.{processing}.log"
    shell:
        """
        checkm lineage_wf -t {params.threads} -x fa {input} {params.out} &> {log}
        checkm lineage_wf -t {params.threads} -x fasta {input} {params.out} &> {log}
        checkm qa -t {params.threads} {output} {params.out} &> {log}
        """

'''
# Further refine bins using refineM
rule run_refinem:
    input:
        bam=expand("Bam/Original/{sample}.sorted.bam", sample=config['samples']),
    params:
        assembly="../input/Aseembly/{index}.fasta",
        reference=config["reference"],
        mb=directory("Maxbin/")
    conda:
        "envs/refinem.yaml"
    output:
        directory("RefineM")
    log:
        "logs/refinem.log"
    shell:
        "python scripts/refinem_snakemake.py -a {params.assembly} -b ../{input.mb} -m ../{input.bam} -s RefineM -r {params.reference} &> {log}"
# Change the below variable!!!
#rm_path = "Default"
rule run_refinem2:
    input:
        bam=expand("Bam/{mypath}/{sample}.sorted.bam", mypath=rm_path, sample=config['samples']),
        mb=directory("Maxbin/{path}/")
    params:
        assembly="../input/Aseembly/{index}.fasta",
        reference=config["reference"]
    conda:
        "envs/refinem.yaml"
    output:
        directory("RefineM/{path}")
    log:
        "logs/refinem_{path}.log"
    shell:
        "python scripts/refinem_snakemake.py -a {params.assembly} -b ../{input.mb} -m ../{input.bam} -s RefineM -r {params.reference} &> {log}"
# Estimate completion and contamination after refinement
'''

