rule build_transcriptome_fasta:
    input:
        "stringtie/stringtie_merged.gtf"
    output:
         "transdecoder/stringtie_cdna.fa"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    params:
        genome=config["genome"] 
    shell:
        "gtf_genome_to_cdna_fasta.pl {input} {params.genome} > {output}"
