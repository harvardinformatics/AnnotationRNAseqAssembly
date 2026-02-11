def getBlastOutfileList(wildcards):
   checkpoint_output = checkpoints.split_longestorfs_fasta.get(**wildcards).output[0]
   return expand("results/transdecoder/blastp/blastp_chunk{i}.tsv",
             i=glob_wildcards(os.path.join(checkpoint_output, "longest_orfs_chunk{i}.fasta")).i)

localrules: transdecoder_orfs2genomegff3,concat_blastp_outputs, split_longestorfs_fasta, predict_mover

rule build_transcriptome_fasta:
    input:
        "results/stringtie/stringtie_merged.gtf"
    output:
         "results/transdecoder/stringtie_cdna.fa"
    conda:
        "../envs/td2.yml"
    params:
        genome=config["genome"] 
    shell:
        "workflow/scripts/gtf_genome_to_cdna_fasta.pl {input} {params.genome} > {output}"

rule convert_gtf2gff3:
    input:
        "results/stringtie/stringtie_merged.gtf"
    output:
        "results/transdecoder/stringtie_merged.gff3"
    conda:
        "../envs/td2.yml"
    shell:
        "workflow/scripts/gtf_to_alignment_gff3.pl {input} > {output}"

rule transdecoder_longorfs:
    input:
        "results/transdecoder/stringtie_cdna.fa"
    output:
        "results/transdecoder/longest_orfs.pep"
    conda:
        "../envs/td2.yml"
    shell:
        """
        rm results/transdecoder/longest_orfs.pep
        rm results/transdecoder/longest_orfs.cds
        rm results/transdecoder/longest_orfs.gff3 
        TD2.LongOrfs -t {input} -O results/transdecoder
        """

checkpoint split_longestorfs_fasta:
    input:
        "results/transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep"
    output:
        directory("results/transdecoder/blastp/chunks/")
    conda:
        "../envs/td2.yml"
    shell:
       """
        python workflow/scripts/FastaSplitter.py -f {input} -maxn 1000 -o {output}
        """

rule blastp_longestorfs:
    input:
        "results/transdecoder/blastp/chunks/longest_orfs_chunk{chunk}.fasta"
    output:
        "results/transdecoder/blastp/blastp_chunk{chunk}.tsv"
    conda:
        "../envs/blast.yml"
    params:
        dbase=config["blastdbase"]
    shell:
        """
        blastp -max_target_seqs 5 -num_threads {resources.cpus_per_task}  -evalue 1e-4 \
        -query {input} -outfmt 6 -db {params.dbase} > {output}
        """


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
        gff3="stringtie_cdna.fa.transdecoder.gff3",
        bed="stringtie_cdna.fa.transdecoder.bed",
        cds="stringtie_cdna.fa.transdecoder.cds",
        pep="stringtie_cdna.fa.transdecoder.pep"
    conda:
        "../envs/td2.yml"
    shell:
        "TD2.Predict -t {input.stringtie_fasta} --single_best_only --retain_blastp_hits {input.blasthits} -O results/transdecoder"

rule predict_mover:
    input:
        gff3="stringtie_cdna.fa.transdecoder.gff3",
        bed="stringtie_cdna.fa.transdecoder.bed",
        cds="stringtie_cdna.fa.transdecoder.cds",
        pep="stringtie_cdna.fa.transdecoder.pep"
    output:
        "results/transdecoder/stringtie_cdna.fa.transdecoder.gff3",
        "results/transdecoder/"stringtie_cdna.fa.transdecoder.bed",
        "results/transdecoder/"stringtie_cdna.fa.transdecoder.cds",
        "results/transdecoder/stringtie_cdna.fa.transdecoder.pep"

    shell:
        """
        mv {input.gff3} results/transdecoder
        mv {input.bed} results/transdecoder
        mv {input.cds} results/transdecoder
        mv {input.pep} results/transdecoder
        """

rule transdecoder_orfs2genomegff3:
    input:
        cdnagff3="results/transdecoder/stringtie_cdna.fa.transdecoder.gff3",
        stiegff3="results/transdecoder/stringtie_merged.gff3",
        tsfasta="results/transdecoder/stringtie_cdna.fa"
    output:
        "results/transdecoder/stringtie_transdecoder_genomecoords.gff3"    
    conda:
        "../envs/td2.yml"
    shell:
        """
        workflow/scripts/cdna_alignment_orf_to_genome_orf.pl {input.cdnagff3} \
        {input.stiegff3} {input.tsfasta} > {output}
        """
           
