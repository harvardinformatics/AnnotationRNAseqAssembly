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

rule convert_gtf2gff3:
    input:
        "stringtie/stringtie_merged.gtf"
    output:
        "transdecoder/stringtie_merged.gff3"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    shell:
        "gtf_to_alignment_gff3.pl {input} > {output}"
