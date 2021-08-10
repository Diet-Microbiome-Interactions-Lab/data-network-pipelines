genomes, = glob_wildcards("FinalGenomes/{gen}.fna")
print(genomes)
faas, = glob_wildcards("GeneCalls/{value}.faa")


rule all:
    input:
        #expand("RefDBs/{ref}.db", ref=genomes),
        #expand("GeneCalls/{ref}.faa", ref=genomes),
        expand("TigrFamResults/{file}.hmm", file=faas),
        #expand("TigrFamResults/{file}.run_hmm", file=faas).
        expand("Pfam/{file}.pfam", file=genomes),
        #expand("Cog/{file}.cog", file=genomes),
        expand("Kegg/{file}.kegg", file=genomes),
        expand("TigrFamResults/{file}.tigr_added", file=genomes),
        #expand("RAST/{file}-RAST-FAA.txt", file=faas),
        #expand("RAST/{file}.rast_added", file=faas),


rule reformat_fasta:
    input:
        orig="FinalGenomes/{ref}.fna"
    output:
        final="FinalSimplifiedGenomes/{ref}.fna"
    shell:
        """
        anvi-script-reformat-fasta {input.orig} -o {output.final} --simplify-names
        """


rule make_db:
    input:
        gen="FinalSimplifiedGenomes/{ref}.fna",
    output:
        out="RefDBs/{ref}.db"
    shell:
        """
        anvi-gen-contigs-database -T 80 -f {input.gen} -n '{wildcards.ref} F Prausnitzii Project' -o {output.out}
        """

rule run_ko:
    input:
        "RefDBs/{ref}.db"
    output:
        "Kegg/{ref}.kegg"
    shell:
        """
        anvi-run-kegg-kofams -c {input} -T 80 --just-do-it && touch {output}
        """


rule run_pfam:
    input:
        "RefDBs/{ref}.db"
    output:
        "Pfam/{ref}.pfam"
    shell:
        """
        anvi-run-pfams -c {input} -T 80 && touch {output}
        """

rule run_cogs:
    input:
        "RefDBs/{ref}.db"
    output:
        "Cog/{ref}.cog"
    shell:
        """
        anvi-run-ncbi-cogs -T 80 -c {input} && touch {output}
        """

rule get_faas:
    input:
        "RefDBs/{ref}.db"
    output:
        "GeneCalls/{ref}.faa"
    shell:
        """
        anvi-get-sequences-for-gene-calls -c {input} --get-aa-sequences -o {output}
        """

rule run_hmm:
    input:
        "GeneCalls/{file}.faa"
    output:
        one="TigrFamResults/{file}.hmm",
        two="TigrFamResults/{file}.tbl"
    shell:
        """
        hmmsearch -o {output.one} --tblout {output.two} --cpu 80 /depot/lindems/data/Dane/DataBases/TIGRFams/AllTigrHmms.hmm {input}
        """

rule create_import:
    input:
        "TigrFamResults/{file}.tbl"
    output:
        "TigrFamResults/{file}.anvio.txt"
    shell:
        """
        python tigrfam-table.py {input} TFAM-Roles.txt {output}
        """

rule db_import:
    input:
        db="RefDBs/{file}.db",
        imp="TigrFamResults/{file}.anvio.txt"
    output:
        "TigrFamResults/{file}.tigr_added"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp} && touch {output}
        """

rule run_hmms:
    input:
        one="RefDBs/{file}.db",
        #two="TigrFamResults/{file}.tigr_added"
    output:
        "TigrFamResults/{file}.run_hmm"
    shell:
        """
        anvi-run-hmms -c {input.one} -T 80 --just-do-it --also-scan-trnas && touch {output}
        """

rule run_rast_cds:
    input:
        "GeneCalls/{file}.faa"
    output:
        "RAST/{file}-RAST-FAA.txt"
    shell:
        """
        svr_assign_using_figfams < {input} > {output}
        """

rule import_rast:
    input:
        db="RefDBs/{file}.db",
        imp="RAST/{file}-RAST-FAA.txt.anvio"
    output:
        "RAST/{file}.rast_added"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp} && touch {output}
        """
