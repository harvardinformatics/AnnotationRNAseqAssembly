localrules: ncrna_include

rule ncrna_include:
    input:
        tdecgff3="transdecoder/stringtie_transdecoder_genomecoords.gff3",
        stiegtf="stringtie/stringtie_merged.gtf" 
    output:
        "transdecoder/stringtie_transdecoder_genomecoords_ncRNAincluded.gff3"
    shell:
        """
        python workflow/scripts/IntegrateStringtieNoTdecoderOrfTscripts.py \
        -tdecgff {input.tdecgff3} -gtf {input.stiegtf} -gff3out {output}
        """
