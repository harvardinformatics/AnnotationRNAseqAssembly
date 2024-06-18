rule star_1stpass:
    input:
        r1=config["fastqDir"] + "{sample}_1.fastq.gz",
        r2=config["fastqDir"] + "{sample}_2.fastq.gz"
    output:
        "star1stpass/" + "{sample}" + "_STAR1stpassSJ.out.tab"
    conda:
        "../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"]
    shell:
        """
        rm -rf star1stpass/{wildcards.sample}_1stpassSTARtmp
        STAR --runThreadN 8 --genomeDir {params.indexdir} \
        --outFileNamePrefix star1stpass/{wildcards.sample}_STAR1stpass \
        --outTmpDir star1stpass/{wildcards.sample}_1stpassSTARtmp \
        --readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2}) 
        """       

rule star_2ndpass:
    input:
        tablelist = expand("star1stpass/{sample}_STAR1stpassSJ.out.tab",sample=SAMPLES),
        r1=config["fastqDir"] + "{sample}" + "_1.fastq.gz",
        r2=config["fastqDir"] + "{sample}" + "_2.fastq.gz"
    output:
        "star2ndpass/" + "{sample}" + "_STAR2ndpassAligned.out.sam"
    conda:
        "../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"],
        tablestring = ' '.join(expand("star1stpass/{sample}_STAR1stpassSJ.out.tab", sample=SAMPLES))
    shell:
        """
        rm -rf star2ndpass/{wildcards.sample}_2ndpassSTARtmp
        STAR --runThreadN 8 \
        --genomeDir {params.indexdir} \
        --outTmpDir star2ndpass/{wildcards.sample}_2ndpassSTARtmp \
        --sjdbFileChrStartEnd {params.tablestring} \
        --outFileNamePrefix star2ndpass/{wildcards.sample}_STAR2ndpass \
        --readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2})
        """
