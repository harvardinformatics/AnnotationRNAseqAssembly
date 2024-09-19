localrules: add_cds

rule add_cds:
    input:
        tdecgff3="results/transdecoder/stringtie_transdecoder_genomecoords.gff3",
        stiegtf="results/stringtie/stringtie_merged.gtf" 
    output:
        "results/stringtie_merged_wCDSfeatures.gff3"
    conda:
        "../envs/gffread"
    script:
        "../scripts/MergeNcRnaPredstoProteinCodingPreds.py -tdecgff3 {{input.tdecgff3}} -gtf {{input.stiegtf}}" 
