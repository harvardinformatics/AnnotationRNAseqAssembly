localrules: concat_blastp_outputs, split_longestorfs_fasta

def getFileList(filelist):
    fopen=open(filelist,'r')
    filelist = []
    for line in fopen:
        filelist.append(line.strip())
    return filelist


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
        """
        rm -rf transdecoder/stringtie_cdna.fa.transdecoder_dir/ 
        TransDecoder.LongOrfs -t {input} -O transdecoder
        """

checkpoint split_longestorfs_fasta:
    input:
        "transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    output:
        directory("transdecoder/blastp/chunks/")
    conda:
        "../envs/transdecoder.yml"
    shell:
        """
        mkdir -p transdecoder/blastp/chunks
        python workflow/scripts/FastaSplitter.py -f {input} -maxn 1000 -o {output}
        """

rule blastp_longestorfs:
    input:
        "transdecoder/blastp/chunks/longest_orfs_chunk{chunk}.fasta"
    output:
        "transdecoder/blastp/blastp_chunk{chunk}.tsv"
    conda:
        "../envs/blast.yml"
    threads: 16
    params:
        dbase=config["blastdbase"]
    shell:
        """
        blastp -max_target_seqs 5 -num_threads 16  -evalue 1e-4 \
        -query {input} -outfmt 6 -db {params.dbase} > {output}
        """

def getBlastOutfileList(wildcards):
   checkpoint_output = checkpoints.split_longestorfs_fasta.get(**wildcards).output[0]
   return expand("transdecoder/blastp/blastp_chunk{i}.tsv",
             i=glob_wildcards(os.path.join(checkpoint_output, "longest_orfs_chunk{i}.fasta")).i)

rule concat_blastp_outputs:
    input:
        getBlastOutfileList
    output:
        "transdecoder/blastp/longorfs_blastp_concat.tsv"
    shell:
        "cat {input} > {output}" 
