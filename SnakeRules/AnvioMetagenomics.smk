genomes, = glob_wildcards("Assemblies/{gen}_contigs.fasta")
simplified_genomes, = glob_wildcards("Assemblies-Simplified/{fasta}.fna")
faas, = glob_wildcards("UCC-Faas/{value}.faa")

rule all:
    input:
        #expand("ContigDatabases/{ref}.db", ref=genomes),
        #expand("RunHMMs/{ref}.run_hmm.tkn", ref=genomes),
        #expand("UCC-Faas/{ref}.faa", ref=genomes),
        #expand("Kegg/{file}.kegg", file=genomes),
        #expand("Pfam/{file}.pfam", file=genomes),
        #expand("Cog/{file}.cog", file=genomes),
        #expand("RAST/{file}-RAST.txt", file=simplified_genomes),
        expand("RAST/{file}-RAST-FAA.txt", file=faas),
        expand("RAST/{file}.rast_added", file=faas),
        expand("TigrFamResults/{file}.hmm", file=faas),
        expand("TigrFamResults/{file}.anvio.txt", file=faas),
        expand("TigrFamResults/{file}.tigr_added", file=faas),

'''
rule reformat_fasta:
    input:
        orig="Assemblies/{ref}_contigs.fasta"
    output:
        final="Assemblies-Simplified/{ref}.fna"
    shell:
        """
        anvi-script-reformat-fasta {input.orig} -o {output.final} --simplify-names
        """
'''

rule make_contigs_db:
    input:
        gen="Assemblies/{ref}_contigs.fasta",
    output:
        out="ContigDatabases/{ref}.db"
    shell:
        """
        anvi-gen-contigs-database -T 80 -f {input.gen} -n '{wildcards.ref}' -o {output.out}
        """

rule run_hmms:
    input:
        one="ContigDatabases/{ref}.db",
    output:
        "RunHMMs/{ref}.run_hmm.tkn"
    shell:
        """
        anvi-run-hmms -c {input.one} -T 80 --just-do-it --also-scan-trnas && touch {output}
        """

rule get_faas:
    input:
        "ContigDatabases/{ref}.db"
    output:
        "UCC-Faas/{ref}.faa"
    shell:
        """
        anvi-get-sequences-for-gene-calls -c {input} --get-aa-sequences -o {output}
        """

rule run_ko:
    input:
        "ContigDatabases/{ref}.db"
    output:
        "Kegg/{ref}.kegg"
    shell:
        """
        anvi-run-kegg-kofams -c {input} -T 80 --just-do-it && touch {output}
        """

rule run_pfam:
    input:
        "ContigDatabases/{ref}.db"
    output:
        "Pfam/{ref}.pfam"
    shell:
        """
        anvi-run-pfams -c {input} -T 80 && touch {output}
        """

rule run_cogs:
    input:
        "ContigDatabases/{ref}.db"
    output:
        "Cog/{ref}.cog"
    shell:
        """
        anvi-run-ncbi-cogs -T 80 -c {input} && touch {output}
        """

# External Annotation Sources
rule run_rast:
    input:
        fa="Assemblies-Simplified/{file}.fna"
    output:
        rast="RAST/{file}-RAST.txt"
    shell:
        """
        svr_assign_to_dna_using_figfams < {input.fa} > {output.rast}
        """

rule run_rast_cds:
    input:
        "UCC-Faas/{file}.faa"
    output:
        "RAST/{file}-RAST-FAA.txt"
    shell:
        """
        svr_assign_using_figfams < {input} > {output}
        """

rule create_rast_import:
    input:
        "RAST/{file}-RAST-FAA.txt"
    output:
        "RAST/{file}-RAST-FAA.txt.anvio"
    shell:
        """
        python scripts/rast-table.py {input} {output}
        """

rule import_rast:
    input:
        db="ContigDatabases/{file}.db",
        imp="RAST/{file}-RAST-FAA.txt.anvio"
    output:
        "RAST/{file}.rast_added"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp} && touch {output}
        """

rule run_tigr_hmm:
    input:
        "UCC-Faas/{file}.faa"
    output:
        one="TigrFamResults/{file}.hmm",
        two="TigrFamResults/{file}.tbl"
    shell:
        """
        hmmsearch -o {output.one} --tblout {output.two} --cpu 80 /depot/lindems/data/Dane/DataBases/TIGRFams/AllTigrHmms.hmm {input}
        """

rule create_tigr_import:
    input:
        "TigrFamResults/{file}.tbl"
    output:
        "TigrFamResults/{file}.anvio.txt"
    shell:
        """
        python scripts/tigrfam-table.py {input} scripts/TFAM-Roles.txt {output}
        """

rule db_import:
    input:
        db="ContigDatabases/{file}.db",
        imp="TigrFamResults/{file}.anvio.txt"
    output:
        "TigrFamResults/{file}.tigr_added"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp} && touch {output}
        """


