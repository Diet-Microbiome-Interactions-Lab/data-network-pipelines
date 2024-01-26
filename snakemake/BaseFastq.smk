configfile: "config/config.yaml"

samples, = glob_wildcards(f'{config["fastqs"]}/{{sample}}.{config["extension"]}')
uids, = glob_wildcards(f'{config["fastqs"]}/{{sample}}_R1_001.{config["extension"]}')
print(uids)


rule all:
    input:
        expand(f'{config["fastqc_loc"]}/{{sample}}_fastqc.html', sample=samples),
        expand(f'{config["kraken2"]}/{{sample}}-output.txt', sample=uids),
        expand(f'{config["metaspades"]}/{{sample}}/contigs.fasta', sample=uids)


rule run_Fastqc:
    input:
        f'{config["fastqs"]}/{{sample}}.{config["extension"]}'
    params:
        threads=config["threads"],
        outdir=config["fastqc_loc"]
    output:
        html=f'{config["fastqc_loc"]}/{{sample}}_fastqc.html',
        zip=f'{config["fastqc_loc"]}/{{sample}}_fastqc.zip'
    shell:
        """
        fastqc -t {params.threads} --outdir {params.outdir} {input}
        """

rule run_Kaiju:
    input:
        r1=f'{config["fastqs"]}/{{sample}}_R1_001.{config["extension"]}',
        r2=f'{config["fastqs"]}/{{sample}}_R2_001.{config["extension"]}'
    params:
        dmp="/depot/lindems/data/Databases/Kaiju/nodes.dmp",
        fmi="/depot/lindems/data/Databases/Kaiju/kaiju_db_20Nov20.fmi",
    output:
        f'{config["kaiju"]}/{{sample}}.txt'
    shell:
        """
        kaiju -t {params.dmp} -f {params.fmi} -i {input.r1} -j {input.r2} -o {output} -a mem
        """

rule run_Kraken2:
    input:
        r1=f'{config["fastqs"]}/{{sample}}_R1_001.{config["extension"]}',
        r2=f'{config["fastqs"]}/{{sample}}_R2_001.{config["extension"]}'
    params:
        db=f'{config["kraken2_db"]}',
        threads=f'{config["threads"]}',
        uc_out=f'{config["kraken2"]}/{{sample}}-unclassified_#.txt',
        c_out=f'{config["kraken2"]}/{{sample}}-classified_#.txt'
    output:
        output=f'{config["kraken2"]}/{{sample}}-output.txt',
        report=f'{config["kraken2"]}/{{sample}}-output.report'
    shell:
        """
        kraken2 --db {params.db} --threads {params.threads} --unclassified-out {params.uc_out} \
        --classified-out {params.c_out} --output {output.output} --report {output.report} \
        {input.r1} {input.r2}
        """


rule run_Spades:
    input:
        r1=f'{config["fastqs"]}/{{sample}}_R1_001.{config["extension"]}',
        r2=f'{config["fastqs"]}/{{sample}}_R2_001.{config["extension"]}'
    params:
        threads=f'{config["threads"]}',
        mem=f'{config["ram_limit"]}',
        out_dir=directory(f'{config["metaspades"]}/{{sample}}')
    output:
        f'{config["metaspades"]}/{{sample}}/contigs.fasta'
    shell:
        """
        metaspades.py -1 {input.r1} -2 {input.r2} -m {params.mem} -t {params.threads} --meta -o {params.out_dir}
        """