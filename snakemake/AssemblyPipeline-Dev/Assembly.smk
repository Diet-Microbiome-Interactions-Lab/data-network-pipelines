configfile: "config/config.yaml"

# 1) Grab the PE fastq files
samples, = glob_wildcards(f'{config["raw_fqs"]}/{{sample}}.{config["raw_fqs_ext"]}')
# 
uids, = glob_wildcards(f'{config["raw_fqs"]}/{{sample}}_1.{config["raw_fqs_ext"]}')
print(samples)
print(uids)


rule all:
    input:
        expand(f'{config["fastqc_out"]}/{{sample}}_fastqc.html', sample=samples),
        expand(f'{config["bbmerge_out"]}/{{sample}}-merged.fastq', sample=uids),
        expand(f'{config["metaspades_out"]}/{{sample}}/contigs.fasta', sample=uids),
        expand(f'{config["megahit_out"]}/{{sample}}/final.contigs.fa/final.contigs.fa', sample=uids),


rule run_Fastqc:
    input:
        f'{config["raw_fqs"]}/{{sample}}.{config["raw_fqs_ext"]}'
    params:
        threads=config["threads"],
        outdir=config["fastqc_out"]
    # resources:
    #     time="00:10:00",
    #     mem_mb=8000
    output:
        html=f'{config["fastqc_out"]}/{{sample}}_fastqc.html',
        zip=f'{config["fastqc_out"]}/{{sample}}_fastqc.zip'
    log: f'{config["log_folder"]}/run_Fastqc__{{sample}}.{config["log_id"]}.log'
    shell:
        """
        fastqc -t {params.threads} --outdir {params.outdir} {input}
        """

# This rule combines 2 input files into 1 output (-merged.fastq)
rule run_BBMerge:
    input:
        r1=f'{config["raw_fqs"]}/{{sample}}_1.{config["raw_fqs_ext"]}',
        r2=f'{config["raw_fqs"]}/{{sample}}_2.{config["raw_fqs_ext"]}'
    output:
        merged=f'{config["bbmerge_out"]}/{{sample}}-merged.fastq',
        r1_unm=f'{config["bbmerge_out"]}/{{sample}}_1-unmerged.fastq',
        r2_unm=f'{config["bbmerge_out"]}/{{sample}}_2-unmerged.fastq',
        outa=f'{config["bbmerge_out"]}/{{sample}}-adapters.fa'
    # resources:
    #     time="00:30:00",
    #     mem_mb=8000
    log: f'{config["log_folder"]}/run_BBMerge__{{sample}}.{config["log_id"]}.log'
    shell:
        """
        bbmerge.sh in1={input.r1} in2={input.r2} out={output.merged} outu1={output.r1_unm} outu2={output.r2_unm} outa={output.outa}
        """

# This uses the 2 separate files
rule run_Spades:
    input:
        merged_reads=f'{config["bbmerge_out"]}/{{sample}}-merged.fastq'
    params:
        mem=f'{config["ram_limit"]}',
        threads=f'{config["threads"]}',
        out_dir=directory(f'{config["metaspades_out"]}/{{sample}}')
    log: f'{config["log_folder"]}/run_Spades__{{sample}}.{config["log_id"]}.log'
    # resources:
    #     time="04:00:00",
    #     mem_mb=8000
    output:
        f'{config["metaspades_out"]}/{{sample}}/contigs.fasta'
    shell:
        """
        metaspades.py -s {input.merged_reads} -m {params.mem} -t {params.threads} --meta -o {params.out_dir}
        """

# This uses the merged file
rule run_Megahit:
    input:
        merged_reads=f'{config["bbmerge_out"]}/{{sample}}-merged.fastq'
    params:
        memory=f'{config["ram_limit"]}',
        threads=f'{config["threads"]}'
    # resources:
    #     time="04:00:00",
    #     mem_mb=8000
    output:
        outfile=f'{config["megahit_out"]}/{{sample}}/final.contigs.fa/final.contigs.fa'
    log: f'{config["log_folder"]}/run_Megahit__{{sample}}.{config["log_id"]}.log'
    shell:
        """
        megahit -r {input.merged_reads} -m {params.memory} -t {params.threads} -o {output.outfile}
        """
