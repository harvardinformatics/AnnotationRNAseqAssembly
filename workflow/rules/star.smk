def get_splice_tables(sampletable):
    readin = pd.read_table(sampletable)
    samples=readin.loc[:,"sampleid"]
    tables = ["1stpass/%s_STAR1stpassSJ.out.tab" % i for i in samples] 
    return tables

rule star_1stpass:
    input:
        r1=config["fastqDir"] + "{sample}_1.fastq.gz",
        r2=config["fastqDir"] + "{sample}_2.fastq.gz"
    output:
        "1stpass/" + "{sample}" + "_STAR1stpassSJ.out.tab"
    conda:
        "../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"]
    shell:
        """
        rm -rf star2nd/{wildcards.sample}_1stpassSTARtmp
        STAR --runThreadN 8 --genomeDir {params.indexdir} \
        --outFileNamePrefix star1st/{wildcards.sample}_STAR1stpass \
        --outTmpDir star1st/{wildcards.sample}_1stpassSTARtmp \
        --readFilesIn <(gunzip -c {input.r1}) <(gunzip -c (input.r2}) 
        """       

rule star_2ndpass:
    input:
        tablelist = get_splice_tables(config["sampleTable"]),
        r1=config["fastqDir"] + "{sample}" + "_1.fastq.gz",
        r2=config["fastqDir"] + "{sample}" + "_2.fastq.gz"
    output:
        "star2nd/" + "{sample}" + "_STAR2ndpassAligned.out.sam"
    conda:
        "../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"],
        tablestring = " ".join(input.tablelist)
    shell:
        """
        rm -rf star2nd/{wildcards.sample}_2ndpassSTARtmp
        STAR --runThreadN 8 \
        --genomeDir {params.indexdir} \
        --outTmpDir star2nd/{wildcards.sample}_2ndpassSTARtmp \
        --outFileNamePrefix star2nd/{wildcards.sample}_STAR2ndpass \
        --readFilesIn <(gunzip -c {input.r1} <(gunzip -c {input.r2})
        """
