rule star_1stpass:
    input:
        r1=sample2fastq[{sample}]["R1"],
        r2=sample2fastq[{sample}]["R2"],
        index=config["StarIndexDir"] + "SA"
    output:
        "results/star1stpass/" + "{sample}" + "_STAR1stpassSJ.out.tab"
    conda:
        "../envs/star.yml"
    threads: 8
    params:
        indexdir = config["StarIndexDir"]
    shell:
        """
        rm -rf results/star1stpass/{wildcards.sample}_1stpassSTARtmp
        STAR --runThreadN {threads} --genomeDir {params.indexdir} \
        --outFileNamePrefix results/star1stpass/{wildcards.sample}_STAR1stpass \
        --outTmpDir results/star1stpass/{wildcards.sample}_1stpassSTARtmp \
        --readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2}) 
        """       

rule star_2ndpass:
    input:
        tablelist = expand("results/star1stpass/{sample}_STAR1stpassSJ.out.tab",sample=SAMPLES),
        r1=sample2fastq[{sample}]["R1"],
        r2=sample2fastq[{sample}]["R2"],
        index=config["StarIndexDir"] + "SA"
    output:
        "results/star2ndpass/" + "{sample}" + "_STAR2ndpassAligned.out.sam"
    conda:
        "../envs/star.yml"
    threads: 8
    params:
        indexdir = config["StarIndexDir"],
        tablestring = ' '.join(expand("results/star1stpass/{sample}_STAR1stpassSJ.out.tab", sample=SAMPLES))
    shell:
        """
        rm -rf results/star2ndpass/{wildcards.sample}_2ndpassSTARtmp
        STAR --runThreadN {threads} \
        --genomeDir {params.indexdir} \
        --outTmpDir results/star2ndpass/{wildcards.sample}_2ndpassSTARtmp \
        --outSAMstrandField intronMotif \
        --sjdbFileChrStartEnd {params.tablestring} \
        --outFileNamePrefix results/star2ndpass/{wildcards.sample}_STAR2ndpass \
        --readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2})
        """

rule samsort_star:
    input:
        "results/star2ndpass/" + "{sample}" + "_STAR2ndpassAligned.out.sam"
    output:
        "results/star2ndpass/sorted_" + "{sample}" + "_STAR2ndpassAligned.out.bam"
    conda:
        "../envs/samtools.yml"
    threads: 12
    shell:
        """
        rm -f results/star2ndpass/tmp/{wildcards.sample}.aln.sorted*bam
        samtools sort -@ {threads} -T results/star2ndpass/tmp/{wildcards.sample}.aln.sorted -O bam -o {output} {input}
        """ 
