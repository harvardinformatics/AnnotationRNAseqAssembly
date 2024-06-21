localrules: split_longestorfs_fasta, make_subfile_list

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

rule transdecoder_longorfs:
    input:
        "transdecoder/stringtie_cdna.fa"
    output:
        "transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    shell:
        "TransDecoder.LongOrfs -t {input} -O transdecoder" 

rule make_subfile_list:
    input:
        "transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    output:
        "transdecoder/blastp/subfilelist.txt"
    script:
        "../scripts/makeSubfileList.py"


rule split_longestorfs_fasta:
    input:
        "transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    output:
        "transdecoder/blastp/fastasplit.done"
    conda:
        "../envs/transdecoder.yml"
    shell:
        """
        python workflow/scripts/FastaSplitter.py -f {input} -maxn 1000 -o transdecoder/blastp
        touch {output}
        """
