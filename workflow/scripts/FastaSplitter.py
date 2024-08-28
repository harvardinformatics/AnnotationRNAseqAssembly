#!/usr/bin/env python3
import argparse
import os
from Bio import SeqIO
from os.path import basename,exists

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='split fasta files into mulitple files of max specified number of seqs')
    parser.add_argument('-f','--fasta-infile',dest='fastain',type=str,help='input fasta file')
    parser.add_argument('-maxn','--max-number-records',dest='maxn',type=int,help='max number of fasta records per split file')
    parser.add_argument('-o','--output-dir',dest='outdir',type=str,help='directory to send output files, no trailing forward slash')
    opts = parser.parse_args()
    
    file_index = 1
    seqcount = 0
    isExist = exists(opts.outdir)
    if not isExist:
        os.makedirs(opts.outdir)
        
    fout = open('%s/%s_chunk%s.fasta' % (opts.outdir,'.'.join(basename(opts.fastain).split('.')[:-1]),file_index),'w')

    for record in SeqIO.parse(opts.fastain,'fasta'):
        if seqcount <=opts.maxn-1:
            SeqIO.write(record,fout,'fasta')
            seqcount+=1
        else:
            file_index+=1
            fout.close()
            fout = open('%s/%s_chunk%s.fasta' % (opts.outdir,'.'.join(basename(opts.fastain).split('.')[:-1]),file_index),'w')
            SeqIO.write(record,fout,'fasta')
            seqcount=1 
    
    fout.close()
