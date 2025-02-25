def get_star_SAindexNbases():
    genome = open(config["genome"],"r")
    genome_length = 0
    for line in genome:
        if line[0] != ">":
            genome_length+=(len(line.strip()))
    saindex = int(min(14,log2(genome_length)/2 - 1))
    return saindex

rule star_index:
    input:
        config["genome"]
    output:
        config["StarIndexDir"] + "SA"
    conda:
        "../envs/star.yml"
    threads: 24
    params:
        nbases=get_star_SAindexNbases(),
        outdir=config["StarIndexDir"]
    shell:
        """
        STAR --runMode genomeGenerate --genomeSAindexNbases {params.nbases} \
        --runThreadN {resources.cpus_per_task} --genomeDir {params.outdir} \
        --genomeFastaFiles {input}
        """  
    
