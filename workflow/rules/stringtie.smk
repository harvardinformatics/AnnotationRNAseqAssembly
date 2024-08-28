def get_sample_path(samplename,aligner):
    if aligner in ["STAR","star"]:
        return "results/star2ndpass/sorted_%s_STAR2ndpassAligned.out.bam" % samplename
    else:
        raise ValueError("unknown aligner")

def get_stringtie_input(wildcards):
    return get_sample_path(wildcards.sample,config["aligner"])


rule stringtie:
    input:
        get_stringtie_input
    output:
         "results/stringtie/{sample}_stringtie.gtf"
    conda:
        "../envs/stringtie.yml"
    threads: 16
    shell:
        "stringtie {input} -p {threads} -o {output}"

rule stringtie_merge:
    input:
        expand("results/stringtie/{sample}_stringtie.gtf",sample=SAMPLES)
    output:
        "results/stringtie/stringtie_merged.gtf"
    conda:
        "../envs/stringtie.yml"
    threads: 1
    shell:
       """
       rm -f stringtie_gtflist.txt
       for sample in {input}; do echo $sample >> stringtie_gtflist.txt;done
       stringtie -p {threads} --merge stringtie_gtflist.txt -o {output}
       """       
