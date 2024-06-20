def get_sample_path(samplename,aligner):
    if aligner in ["STAR","star"]:
        return "star2ndpass/sorted_%s_STAR2ndpassAligned.out.bam" % samplename
    else:
        raise ValueError("unknown aligner")

def get_stringtie_input(wildcards):
    return get_sample_path(wildcards.sample,config["aligner"])


rule stringtie:
    input:
        get_stringtie_input
    output:
         "stringtie/{sample}_stringtie.gtf"
    conda:
        "../envs/stringtie.yml"
    threads: 16
    shell:
        "stringtie {input} -p {threads} -o {output}"       
