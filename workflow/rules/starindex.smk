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
        "{}SA".format(config["star_index_dir"])
    conda:
        "../envs/star.yml"
    #threads: 24
    resources:
        mem_mb = lambda wildcards, attempt: int(60000 * (2 ** (attempt - 1))),
        runtime = lambda wildcards, attempt: int(2160* (2 ** (attempt - 1))),
        cpus_per_task = 24
    params:
        nbases=get_star_SAindexNbases(),
        outdir=config["star_index_dir"]
    shell:
        """
        STAR --runMode genomeGenerate --genomeSAindexNbases {params.nbases} \
        --runThreadN {resources.cpus_per_task} --genomeDir {params.outdir} \
        --genomeFastaFiles {input}
        """  
    
