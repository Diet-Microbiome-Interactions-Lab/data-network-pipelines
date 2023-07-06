pe_fastqs, num, = glob_wildcards("fastq/{sample}_{num}.fastq.gz")
#se_fastqs, = glob_wildcards("{sample}.fastq.gz")
print(f'PE: ({pe_fastqs},{num})')
#print(f'SE: {se_fastqs}')
rule all:
    input:
        expand("Bams/{fq}.sorted.bam.bai", fq=pe_fastqs),
        #expand("Bams/{fq}.sorted.bam.bai", fq=se_fastqs)

rule create_index:
    input:
        'Assembly/XG_sample0_contigs.fasta'
    params:
        prefix='Assembly/XG'
    priority: 100
    output:
        'Assembly/XG.1.bt2'
    shell:
        """
        bowtie2-build --threads 40 -f {input} {params.prefix}
        """


rule align_pe_bams:
    input:
        index="Assembly/XG.1.bt2",
        pe1="fastq/{fq}_1.fastq.gz",
        pe2="fastq/{fq}_2.fastq.gz"
    params:
        index="Assembly/XG"
    priority: 100
    group: "main"
    output:
        bam="Bams/{fq}.bam"
    shell:
        """
        bowtie2 --threads 128 -k 5 -x {params.index} -1 {input.pe1} -2 {input.pe2} | samtools view -b -o {output.bam}
        """

rule align_bams:
    input:
        index="Assembly/XG.1.bt2",
        fastq="fastq/SE_{fq}_filtered.fastq.gz"
    params:
        index="Assembly/XG"
    group: "main"
    output:
        bam="Bams/{fq}.bam"
    shell:
        """
        bowtie2 --threads 128 -k 5 -x {params.index} -U {input.fastq} | samtools view -b -o {output.bam}
        """

rule sort_bams:
    input:
        bam="Bams/{fq}.bam",
    output:
        sort="Bams/{fq}.sorted.bam"
    group: "main"
    shell:
        """
        samtools sort -@128 -m1G -o {output.sort} {input.bam}
        """

rule index_bams:
    input:
        sort="Bams/{fq}.sorted.bam"
    output:
        bai="Bams/{fq}.sorted.bam.bai"
    group: "main"
    shell:
        """
        samtools index -@128 {input.sort}
        """
