genomes, = glob_wildcards("Assembly/{gen}.fasta")

rule all:
    input:
        expand("FinalSimplifiedGenomes/{ref}.fna", ref=genomes),
        expand("ContigDB-Sample0/{ref}.db", ref=genomes),
        expand("Annotations/HMMs/{file}.run_hmm", file=genomes),
        expand("Annotations/Cog/{file}.cog", file=genomes),
        expand("Annotations/Kegg/{file}.kegg", file=genomes),
        expand("Annotations/Pfam/{file}.pfam", file=genomes),
        #expand("FAAs/{ref}.faa", ref=genomes),
        #expand("GeneCalls/{ref}.gff", ref=genomes),
        #expand("Annotations/TigrFamResults/{file}.tigr_added", file=genomes),
        #expand("Annotations/RAST/{file}.rast_added", file=genomes),
        #expand("Annotations/Annotations-Exported/{file}.gff3", file=genomes),
        #expand("GFF3-Final/{file}.gff3", file=genomes),

# INTERNAL PHASE
rule Reformat_Fasta:
    input:
        orig="Assembly/{ref}.fasta"
    output:
        final="FinalSimplifiedGenomes/{ref}.fna"
    group: "main"
    shell:
        """
        anvi-script-reformat-fasta {input.orig} -o {output.final} --simplify-names --seq-type NT
        """

rule Create_Database:
    input:
        gen="FinalSimplifiedGenomes/{ref}.fna",
    output:
        out="ContigDB-Sample0/{ref}.db"
    group: "main"
    shell:
        """
        anvi-gen-contigs-database -T 80 -f {input.gen} -n '{wildcards.ref} F Prausnitzii Project' -o {output.out}
        """

rule Run_HMMs:
    input:
        one="ContigDB-Sample0/{file}.db",
    output:
        touch("Annotations/HMMs/{file}.run_hmm")
    group: "main"
    shell:
        """
        anvi-run-hmms -c {input.one} -T 80 --just-do-it --also-scan-trnas
        """

rule Run_COGs:
    input:
        "ContigDB-Sample0/{ref}.db"
    output:
        touch("Annotations/Cog/{ref}.cog")
    group: "main"
    shell:
        """
        anvi-run-ncbi-cogs -T 80 -c {input}
        """

rule Run_KOFams:
    input:
        "ContigDB-Sample0/{ref}.db"
    output:
        touch("Annotations/Kegg/{ref}.kegg")
    group: "main"
    shell:
        """
        anvi-run-kegg-kofams -c {input} -T 80 --just-do-it
        """

rule Run_PFams:
    input:
        "ContigDB-Sample0/{ref}.db"
    output:
        touch("Annotations/Pfam/{ref}.pfam")
    group: "main"
    shell:
        """
        anvi-run-pfams -c {input} -T 80
        """

# EXPORTING PHASE
rule Export_FAA:
    input:
        "ContigDB-Sample0/{ref}.db"
    output:
        "FAAs/{ref}.faa"
    group: "main"
    shell:
        """
        anvi-get-sequences-for-gene-calls -c {input} --get-aa-sequences -o {output}
        """

rule Export_Gene_Calls:
    input:
        "ContigDB-Sample0/{ref}.db"
    output:
        "GeneCalls/{ref}.gff"
    group: "main"
    shell:
        """
        anvi-export-gene-calls -c {input} -o {output} --gene-caller prodigal
        """

# EXTERNAL ANNOTATION
rule RAST_Run:
    input:
        "FAAs/{file}.faa"
    output:
        "Annotations/RAST/{file}-RAST-FAA.txt"
    group: "main"
    shell:
        """
        svr_assign_using_figfams < {input} > {output}
        """

rule RAST_Reformat:
    input:
        "Annotations/RAST/{file}-RAST-FAA.txt"
    output:
         "Annotations/RAST/{file}-RAST-FAA.txt.anvio"
    group: "main"
    shell:
        """
        python scripts/rast-table.py {input} {output} 
        """

rule RAST_Import:
    input:
        db="ContigDB-Sample0/{file}.db",
        imp="Annotations/RAST/{file}-RAST-FAA.txt.anvio"
    output:
        touch("Annotations/RAST/{file}.rast_added")
    group: "main"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp}
        """

rule TigrFam_Run:
    input:
        "FAAs/{file}.faa"
    output:
        one="Annotations/TigrFamResults/{file}.hmmer.TIGR.hmm",
        two="Annotations/TigrFamResults/{file}.hmmer.TIGR.tbl"
    group: "main"
    shell:
        """
        hmmsearch -o {output.one} --tblout {output.two} --cpu 80 /depot/lindems/data/Databases/TIGRFams/AllTigrHmms.hmm {input}
        """

rule TigrFam_Reformat:
    input:
        "Annotations/TigrFamResults/{file}.hmmer.TIGR.tbl"
    output:
        "Annotations/TigrFamResults/{file}.hmmer.TIGR.anvio.tbl"
    group: "main"
    shell:
        """
        python scripts/tigrfam-table.py {input} scripts/TFAM-Roles.txt {output}
        """

rule TigrFam_Import:
    input:
        db="ContigDB-Sample0/{file}.db",
        imp="Annotations/TigrFamResults/{file}.hmmer.TIGR.anvio.tbl"
    output:
        touch("Annotations/TigrFamResults/{file}.tigr_added")
    group: "main"
    shell:
        """
        anvi-import-functions -c {input.db} -i {input.imp}
        """

# EXPORTING ANNOTATIONS
rule export_annotations:
    input:
        db="ContigDB-Sample0/{file}.db"
    params:
        annotations="FigFams,KEGG_Module,COG20_PATHWAY,TIGRFAM,KOfam,KEGG_Class,Transfer_RNAs,COG20_FUNCTION,Pfam,COG20_CATEGORY"
    output:
        out="Annotations/Annotations-Exported/{file}.gff3"
    group: "exporting"
    priority: -1
    shell:
        """
        anvi-export-functions -c {input.db} --annotation-sources {params.annotations} -o {output.out}
        """

rule reformat_gff3:
    input:
        anvio_annotations="Annotations/Annotations-Exported/{ref}.gff3",
        gene_calls="GeneCalls/{ref}.gff"
    output:
        gff3_final="GFF3-Final/{ref}.gff3"
    group: "exporting"
    priority: -1
    shell:
        """
        python scripts/combineFunctionsAndGeneCalls.py {input.gene_calls} {input.anvio_annotations} {output.gff3_final}
        """
