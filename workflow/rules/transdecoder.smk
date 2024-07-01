localrules: transdecoder_orfs2genomegff3,concat_blastp_outputs, split_longestorfs_fasta

rule build_transcriptome_fasta:
    input:
        "results/stringtie/stringtie_merged.gtf"
    output:
         "results/transdecoder/stringtie_cdna.fa"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    params:
        genome=config["genome"] 
    shell:
        "gtf_genome_to_cdna_fasta.pl {input} {params.genome} > {output}"

rule convert_gtf2gff3:
    input:
        "results/stringtie/stringtie_merged.gtf"
    output:
        "results/transdecoder/stringtie_merged.gff3"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    shell:
        "gtf_to_alignment_gff3.pl {input} > {output}"

rule transdecoder_longorfs:
    input:
        "results/transdecoder/stringtie_cdna.fa"
    output:
        "results/transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    conda:
        "../envs/transdecoder.yml"
    threads: 1
    shell:
        """
        rm -rf {input}.transdecoder_dir/ 
        TransDecoder.LongOrfs -t {input} -O results/transdecoder
        """

checkpoint split_longestorfs_fasta:
    input:
        "results/transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    output:
        directory("results/transdecoder/blastp/chunks/")
    conda:
        "../envs/transdecoder.yml"
    shell:
        """
        #mkdir -p {output}
        python workflow/scripts/FastaSplitter.py -f {input} -maxn 1000 -o {output}
        """

rule blastp_longestorfs:
    input:
        "results/transdecoder/blastp/chunks/longest_orfs_chunk{chunk}.fasta"
    output:
        "results/transdecoder/blastp/blastp_chunk{chunk}.tsv"
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
   return expand("results/transdecoder/blastp/blastp_chunk{i}.tsv",
             i=glob_wildcards(os.path.join(checkpoint_output, "longest_orfs_chunk{i}.fasta")).i)

rule concat_blastp_outputs:
    input:
        getBlastOutfileList
    output:
        "results/transdecoder/blastp/longorfs_blastp_concat.tsv"
    shell:
        """
        cat {input} > {output}
        rm {input}
        """

rule transdecoder_predict:
    input:
        stringtie_fasta="results/transdecoder/stringtie_cdna.fa",
        blasthits="results/transdecoder/blastp/longorfs_blastp_concat.tsv" 
    output:
        "results/transdecoder/stringtie_cdna.fa.transdecoder.gff3"
    conda:
        "../envs/transdecoder.yml"
    shell:
        "TransDecoder.Predict -t {input.stringtie_fasta} --single_best_only --retain_blastp_hits {input.blasthits} -O results/transdecoder" 

rule transdecoder_orfs2genomegff3:
    input:
        cdnagff3="results/transdecoder/stringtie_cdna.fa.transdecoder.gff3",
        stiegff3="results/transdecoder/stringtie_merged.gff3",
        tsfasta="results/transdecoder/stringtie_cdna.fa"
    output:
        "results/transdecoder/stringtie_transdecoder_genomecoords.gff3"    
    conda:
        "../envs/transdecoder.yml"
    shell:
        """
        cdna_alignment_orf_to_genome_orf.pl {input.cdnagff3} \
        {input.stiegff3} {input.tsfasta} > {output}
        """
           
