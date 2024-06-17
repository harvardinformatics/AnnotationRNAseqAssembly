rule star_1stpass:
    input:
        r1=config["fastqDir"] + "{sample}" + "_1_val_1.fq.gz",
        r2=config["fastqDir"] + "{sample}" + "_2_val_2.fq.gz"
    output:
        "1stpass/" + "{sample}" + "_STAR1stpassSJ.out.tab"
    conda:
        "../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"]
    shell:
        "rm -rf star1st/{wildcards.sample}_1stpassSTARtmp;"
        "STAR --runThreadN {threads} --genomeDir {params.indexdir} " 
         "--outFileNamePrefix star1st/{wildcards.sample}_STAR1stpass " 
         "--outTmpDir star1xt/{wildcards.sample}_1stpassSTARtmp "
         "--readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2})"

rule star_2ndpass:
    input:
        tablelist = expand("star1st/{sample}_STAR1stpassSJ.out.tab", sample=SAMPLES),
        r1=config["fastqDir"] + "{sample}" + "_1_val_1.fq.gz",
        r2=config["fastqDir"] + "{sample}" + "_2_val_2.fq.gz"
    output:
        "star2nd/" + "{sample}" + "_STAR2ndpassAligned.out.sam"
    conda:
        ../envs/star.yml"
    params:
        indexdir = config["StarIndexDir"],
        tablestring = ' '.join(expand("star1st/{sample}_STAR1stpassSJ.out.tab", sample=SAMPLES))
    shell:
        "rm -rf star2nd/{wildcards.sample}_2ndpassSTARtmp;"
        "STAR --runThreadN {threads} "
        "--genomeDir {params.indexdir} --outSAMstrandField intronMotif "
        "--outTmpDir star2nd/{wildcards.sample}_2ndpassSTARtmp "
        "--sjdbFileChrStartEnd {params.tablestring} "
        "--outFileNamePrefix star2nd/{wildcards.sample}_STAR2ndpass "
        "--readFilesIn <(gunzip -c {input.r1}) <(gunzip -c {input.r2})" 
     
#rule samsort_star:
#    input:
#        config["Star2ndPassOutdir"] + "{sample}" + "_STAR2ndpassAligned.out.sam"
#    output:
#        config["StarSamsortOutdir"] + "sorted_" + "{sample}" + "_STAR2ndpass.bam"
#    conda:
#        "envs/samtools.yml"
#    threads:
#        res_config['samsort']['threads']
#    resources:
#        mem_mb = lambda wildcards, attempt: attempt * 1.5 * res_config['samsort']['mem_mb'],
#        time = res_config['samsort']['time']
#    params:
#        outdir = config["StarSamsortOutdir"]
#    shell:
#        "rm -f {params.outdir}tmp/{wildcards.sample}.aln.sorted*bam;"
#        "samtools sort -@ {threads} -T {params.outdir}tmp/{wildcards.sample}.aln.sorted -O bam -o {output} {input}" 
