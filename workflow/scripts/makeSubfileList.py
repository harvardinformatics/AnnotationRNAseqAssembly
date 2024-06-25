from math import ceil
from os import system
def make_subfile_list():
    fopen= open('transdecoder/stringtie_cdna.fa.transdecoder_dir/longest_orfs.pep','r')
    seqs_per_file = 1000
    counter = 0
    for line in fopen:
        if line[0] == '>':
            counter+=1
    fout = open('transdecoder/blastp/subfilelist.txt','w')
    for i in range(ceil(counter/seqs_per_file)):
        fout.write('transdecoder/blastp/longest_orfs_%s.fasta\n' % str(i+1))
    fout.close()
    system("touch transdecoder/blastp/makefilelist.done")


make_subfile_list()    
