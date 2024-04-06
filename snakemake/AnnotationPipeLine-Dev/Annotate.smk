import os
from datetime import datetime

tstamp = datetime.now().strftime("%d-%m-%Y_%H-%M-%S")


configfile: "config/config.yaml"


# 1) Using pattern matching, grab all of the initial input
sample_ids, = glob_wildcards(
    f'{config["raw_sequence"]}/{{sample}}.{config["raw_sequence_ext"]}'
)
print(sample_ids)
# ---------- # ---------- #


rule all:
    input:
        f"Setup/All/{config['analysis_name']}.setup",  # Setup stuff!
        expand("Annotations/All/{sample}.tkn", sample=sample_ids),  # Annotations
        expand(f'{config["anvio_contig_db"]}/{{sample}}.db', sample=sample_ids),
        #expand("FAAs/{sample}.faa", sample=sample_ids),
        #expand("GeneCalls/{sample}.genes", sample=sample_ids),
        #expand("Annotations/Other/{dbs}.estimate_scgs", dbs=glob_wildcards(f'{config["anvio_contig_db"]}/{{value}}.db').value),
        expand("GFF3-Final/{sample}.gff3", sample=sample_ids)


# Ensure each
rule Reformat_Fasta:
    input:
        origin=f'{config["raw_sequence"]}/{{sample}}.{config["raw_sequence_ext"]}',
    output:
        final=f'{config["verified_sequence"]}/{{sample}}-VERIFIED.{config["raw_sequence_ext"]}',
    log:
        f'{config["log_folder"]}/Reformat_Fasta__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    shell:
        """
        anvi-script-reformat-fasta {input.origin} -o {output.final} --simplify-names --seq-type NT &> {log}
        """


rule Create_Database:
    input:
        gen=f'{config["verified_sequence"]}/{{sample}}-VERIFIED.{config["raw_sequence_ext"]}',
    output:
        out=f'{config["anvio_contig_db"]}/{{sample}}.db',
    params:
        title="This is my project",
    log:
        f'{config["log_folder"]}/Create_Database__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    shell:
        """
        anvi-gen-contigs-database -T {threads} -f {input.gen} -n '{wildcards.sample} {params.title}' -o {output.out} &> {log}
        """


# ~~~ Setup Anvio for Annotations ~~~ #
rule Setup_Cazymes:
    output:
        touch(f"Setup/Cazyme/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_Cazymes__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 25
    shell:
        """
        anvi-setup-cazymes
        """


rule Setup_Cogs:
    output:
        touch(f"Setup/Cog/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_Cog__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 25
    shell:
        """
        anvi-setup-ncbi-cogs
        """


rule Setup_Kegg:
    output:
        touch(f"Setup/Kegg/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_Kegg__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 25
    shell:
        """
        anvi-setup-kegg-data --mode modules
        """


rule Setup_Pfam:
    output:
        touch(f"Setup/Pfam/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_Pfam__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 25
    shell:
        """
        anvi-setup-pfams
        """


rule Setup_SCG:
    output:
        touch(f"Setup/SCG/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_SCG__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 25
    shell:
        """
        anvi-setup-scg-taxonomy
        """


rule Setup_All:
    output:
        touch(f"Setup/Cazyme/{config['analysis_name']}.setup"),
        touch(f"Setup/Cog/{config['analysis_name']}.setup"),
        touch(f"Setup/Kegg/{config['analysis_name']}.setup"),
        touch(f"Setup/Pfam/{config['analysis_name']}.setup"),
        touch(f"Setup/SCG/{config['analysis_name']}.setup"),
        touch(f"Setup/All/{config['analysis_name']}.setup"),
    log:
        f'{config["log_folder"]}/Setup_All__{config["analysis_name"]}.{config["log_id"]}.log',
    threads: config["threads"]
    shell:
        """
        anvi-setup-cazymes --reset
        anvi-setup-ncbi-cogs --reset -T {threads}
        anvi-setup-kegg-data --mode modules --reset -T {threads}
        anvi-setup-pfams --reset
        anvi-setup-scg-taxonomy --reset -T {threads}
        """


# ~~~ Internal Anvio Annotations ~~~ #
# ~~~ Start ~~~ #
rule Run_HMMs:
    input:
        one=ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        touch("Annotations/HMMs/{sample}.run_hmm"),
    log:
        f'{config["log_folder"]}/Run_HMMs__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "internal-annotation"
    priority: 25
    shell:
        """
        anvi-run-hmms -c {input.one} -T {threads} --just-do-it --also-scan-trnas &> {log}
        """


rule Run_CAZymes:
    # Requires anvi-setup-cazyme
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        touch("Annotations/Cazyme/{sample}.cazyme"),
    log:
        f'{config["log_folder"]}/Run_CAZymes__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "internal-annotation"
    priority: 25
    shell:
        """
        anvi-run-cazymes -c {input} -T {threads} &> {log}
        """


rule Run_COGs:
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        touch("Annotations/Cog/{sample}.cog"),
    log:
        f'{config["log_folder"]}/Run_COGs__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "internal-annotation"
    priority: 25
    shell:
        """
        anvi-run-ncbi-cogs -T {threads} -c {input} &> {log}
        """


rule Run_Kegg:
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        touch("Annotations/Kegg/{sample}.kegg"),
    log:
        f'{config["log_folder"]}/Run_Kegg__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "internal-annotation"
    priority: 25
    shell:
        """
        anvi-run-kegg-kofams -c {input} -T {threads} --include-stray-KOs --just-do-it &> {log}
        """


rule Run_PFams:
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        touch("Annotations/Pfam/{sample}.pfam"),
    log:
        f'{config["log_folder"]}/Run_PFams__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "internal-annotation"
    priority: 25
    shell:
        """
        anvi-run-pfams -c {input} -T {threads} &> {log}
        """


rule Run_SCG_Taxonomy:
    input:
        db=ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        estimate_out="Annotations/Other/{sample}.estimate_scgs",
    log:
        f'{config["log_folder"]}/Run_SCGs__{{sample}}.{config["log_id"]}.log',
    group:
        "internal-annotation"
    threads: config["threads"]
    shell:
        """
        anvi-run-scg-taxonomy -c {input.db} -T {threads} &> {log}
        anvi-estimate-scg-taxonomy -c {input.db} --output-file {output.estimate_out} -T {threads} --metagenome-mode
        """


rule Run_Anvio_Internal:
    input:
        hmms="Annotations/HMMs/{sample}.run_hmm",
        cazy="Annotations/Cazyme/{sample}.cazyme",
        cogs="Annotations/Cog/{sample}.cog",
        kegg="Annotations/Kegg/{sample}.kegg",
        pfams="Annotations/Pfam/{sample}.pfam",
        scgs="Annotations/Other/{sample}.estimate_scgs",
    output:
        touch("Annotations/All/{sample}.tkn"),
    group:
        "internal-annotation"
    shell:
        """
        echo 'Running...'
        """


# ~~~ End ~~~ #


# EXPORTING PHASE
rule Export_FAA:
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        "FAAs/{sample}.faa",
    log:
        f'{config["log_folder"]}/Export_FAA__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 15
    shell:
        """
        anvi-get-sequences-for-gene-calls -c {input} --get-aa-sequences -o {output} &> {log}
        """





# EXTERNAL ANNOTATION
rule RAST_Run:
    input:
        "FAAs/{sample}.faa",
    output:
        "Annotations/RAST/{sample}-RAST-FAA.txt",
    # log: f'{config["log_folder"]}/RAST_Run__{{sample}}.{config["log_id"]}.log'
    group:
        "main"
    priority: 10
    shell:
        """
        svr_assign_using_figfams < {input} > {output}
        """


rule RAST_Reformat:
    input:
        "Annotations/RAST/{sample}-RAST-FAA.txt",
    output:
        "Annotations/RAST/{sample}-RAST-FAA.txt.anvio",
    log:
        f'{config["log_folder"]}/RAST_Reformat__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 10
    shell:
        """
        rast-table.py {input} {output} &> {log}
        """


rule RAST_Import:
    input:
        db=ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
        imp="Annotations/RAST/{sample}-RAST-FAA.txt.anvio",
    output:
        touch("Annotations/RAST/{sample}.rast_added"),
    log:
        f'{config["log_folder"]}/RAST_Import__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 10
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp} &> {log}
        """


rule TigrFam_Run:
    input:
        "FAAs/{sample}.faa",
    params:
        db=f'{config["tigrfam_db"]}',
    output:
        one="Annotations/TigrFamResults/{sample}.hmmer.TIGR.hmm",
        two="Annotations/TigrFamResults/{sample}.hmmer.TIGR.tbl",
    log:
        f'{config["log_folder"]}/TigrFam_Run__{{sample}}.{config["log_id"]}.log',
    threads: config["threads"]
    group:
        "main"
    priority: 10
    shell:
        """
        hmmsearch -o {output.one} --tblout {output.two} --cpu {threads} {params.db} {input} &> {log}
        """


rule TigrFam_Reformat:
    input:
        "Annotations/TigrFamResults/{sample}.hmmer.TIGR.tbl",
    output:
        "Annotations/TigrFamResults/{sample}.hmmer.TIGR.anvio.tbl",
    params:
        tfam="/depot/lindems/data/Dane/CondaEnvironments/SnakeStuff/scripts/TFAM-Roles.txt",
    log:
        f'{config["log_folder"]}/TigrFam_Reformat__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 10
    shell:
        """
        tigrfam-table.py {input} {params.tfam} {output} &> {log}
        """


rule TigrFam_Import:
    input:
        db=ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
        imp="Annotations/TigrFamResults/{sample}.hmmer.TIGR.anvio.tbl",
    output:
        touch("Annotations/TigrFamResults/{sample}.tigr_added"),
    log:
        f'Logs/TigrFam_Import__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 10
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp}  &> {log}
        """


rule CAZyme_Run:
    input:
        fasta=f'{config["verified_sequence"]}/{{sample}}-VERIFIED.{config["raw_sequence_ext"]}',
    params:
        outdir=f"Annotations/DBCan4/{{sample}}/",
        outpref=f"{{sample}}_",
        db=f'{config["cazyme_db"]}',
    output:
        final=f"Annotations/DBCan4/{{sample}}/{{sample}}_overview.txt",
    shell:
        """
        run_dbcan {input.fasta} prok --out_dir {params.outdir} --tf_cpu 10 --out_pre {params.outpref} \
        --db_dir {params.db} -c cluster
        """


# EXPORTING ANNOTATIONS
rule Export_Gene_Calls:
    input:
        ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
    output:
        "GeneCalls/{sample}.genes",
    log:
        f'{config["log_folder"]}/Export_Gene_Calls__{{sample}}.{config["log_id"]}.log',
    group:
        "main"
    priority: 15
    shell:
        """
        anvi-export-gene-calls -c {input} -o {output} --gene-caller prodigal &> {log}
        """

rule Export_Annotations:
    input:
        db=ancient(f'{config["anvio_contig_db"]}/{{sample}}.db'),
        cazy="Annotations/Cazyme/{sample}.cazyme",
        cogs="Annotations/Cog/{sample}.cog",
        hmms="Annotations/HMMs/{sample}.run_hmm",
        kegg="Annotations/Kegg/{sample}.kegg",
        pfams="Annotations/Pfam/{sample}.pfam",
        #figfams = "Annotations/RAST/{sample}.rast_added",
        # tigrfams="Annotations/TigrFamResults/{sample}.tigr_added",
    output:
        out="Annotations/Annotations-Exported/{sample}.functions",
    log:
        f'Logs/Export_Annotations__{{sample}}.{config["log_id"]}.log',
    params:
        annotations=config["annotation_sources"],
        # annotations = "KEGG_Module,COG20_PATHWAY,TIGRFAM,KOfam,KEGG_Class,COG20_FUNCTION,Pfam,COG20_CATEGORY"
    group:
        "exporting"
    priority: 0
    shell:
        """
        anvi-export-functions -c {input.db} --annotation-sources {params.annotations} -o {output.out} &> {log}
        """


rule Reformat_Gff3:
    input:
        anvio_annotations="Annotations/Annotations-Exported/{sample}.functions",
        gene_calls="GeneCalls/{sample}.genes",
    output:
        gff3_final="GFF3-Final/{sample}.gff3",
    log:
        f'Logs/Reformat_Gff3__{{sample}}.{config["log_id"]}.log',
    group:
        "exporting"
    priority: 0
    shell:
        """
        combineFunctionsAndGeneCalls.py {input.gene_calls} {input.anvio_annotations} {output.gff3_final} &> {log}
        """
