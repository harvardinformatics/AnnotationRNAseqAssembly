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
    params:
        strandedness=(lambda s: '--rf' if s == 'rf' else ('--fr' if s == 'fr' else ''))(config['strandedness'])
    shell:
        "stringtie {input} -p {resources.cpus_per_task} {params.strandedness} -o {output}"
rule stringtie_merge:
    input:
        expand("results/stringtie/{sample}_stringtie.gtf",sample=SAMPLES)
    output:
        gtflist=temp("stringtie_gtflist.txt"),
        gtf="results/stringtie/stringtie_merged.gtf"
    conda:
        "../envs/stringtie.yml"
    shell:
       """
       for sample in {input}; do echo $sample >> {output.gtflist};done
       stringtie -p {resources.cpus_per_task} --merge {output.gtflist} -o {output.gtf}
       """       
