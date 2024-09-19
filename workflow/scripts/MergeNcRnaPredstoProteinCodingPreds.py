import argparse
from subprocess import Popen,PIPE
from glob import glob
import re

fields = ['seqid', 'source', 'type', 'start',
          'end', 'score', 'strand', 'phase', 'attributes']

def CreateGeneIntervalDict(gff3):
    genedict = {}
    with open(gff3,'r') as fopen:
        for line in fopen:
            if line[0] != '#':
                linedict = dict(zip(fields,line.strip().split('\t')))
                if linedict['type'] == 'transcript':
                    linedict['attributes'] = linedict['attributes'].split(';')[1].replace('geneID=','ID=')
                    geneid = linedict['attributes'].split('=')[1]
                 
                    if geneid not in genedict:
                        genedict[geneid] = linedict
                        genedict[geneid]['type'] = 'gene'

                    else:
                        start = min(int(linedict['start']),int(genedict[geneid]['start']))
                        end = max(int(linedict['end']),int(genedict[geneid]['end']))
                        genedict[geneid]['start'] =  start
                        genedict[geneid]['end'] =  end
    
    return genedict                       


def ParseStringtieAttributes(linedict):
    attribute_list = linedict['attributes'].split(';')
    attribute_dict = {}
    for attribute in attribute_list:
        key,value = attribute.split('=')
        attribute_dict[key] = value
    if linedict['type'] == 'transcript':
        attribute_dict['Parent'] = attribute_dict['geneID']
    return attribute_dict

def ParseTdecoderAttributes(linedict):
    """
    parser for the attributes field (column 9)
    of a stringtie gff3 file
    """
    attribute_list = linedict['attributes'].split(';')
    attribute_dict = {}
    for attribute in attribute_list:
        key,value = attribute.split('=')
        value = value.split('^')[0].split('|')[0].split('.p')[0]
        attribute_dict[key] = value

    return attribute_dict



if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Tools to merge stringtie features without OFS into the transdecoder annotation gff3')
    parser.add_argument('-tdecgff3','--transdecoder-genomecoord-gff3',dest='tdecgff3',type=str,help='transdecoder genome-coordinate annotation gff3')
    parser.add_argument('-gtf','--stringtie-gtf',dest='gtf',type=str,help='stringtie annotation gtf file')
    opts = parser.parse_args()

    # Create gff3 version of raw merged stringtie gtf if doesn't exist
    if len(glob('{}'.format(opts.gtf.replace('gtf','gff3')))) == 0:
        gffread_cmd = 'gffread {} -o {}'.format(opts.gtf, opts.gtf.replace('gtf','gff3'))
        gffreader = Popen(gffread_cmd,shell=True,stderr=PIPE,stdout=PIPE)
        reader_out,reader_err = gffreader.communicate()
        if gffreader.returncode == 0:
            pass
        else:
            raise Exception(reader_err)


    # create an interval dict for gene-level features from the created stringtie gff3

    gene_interval_dict = CreateGeneIntervalDict('{}'.format(opts.gtf.replace('gtf','gff3')))   


    # build data structures to store transdecoder annotation features
    tdec_gene_dict = {}
    tdec_transcript_dict = {}

    tdec_open = open(opts.tdecgff3,'r')
    for line in tdec_open:
        if line[0] != '#' and line !="\n":
            linedict = dict(zip(fields,line.strip().split()))
            attribute_dict = ParseTdecoderAttributes(linedict)
            if linedict['type'] == 'gene':
                tdec_gene_dict[attribute_dict['ID']] = line
            elif linedict['type'] == 'mRNA':
                tdec_transcript_dict[attribute_dict['ID']] = {}
                tdec_transcript_dict[attribute_dict['ID']]['mRNA'] = line
                tdec_transcript_dict[attribute_dict['ID']]['exons'] = []
                tdec_transcript_dict[attribute_dict['ID']]['cds'] = []
                tdec_transcript_dict[attribute_dict['ID']]['three_prime_UTR'] = []  
                tdec_transcript_dict[attribute_dict['ID']]['five_prime_UTR'] = [] 
            elif linedict['type'] == 'exon':
                tdec_transcript_dict[attribute_dict['Parent']]['exons'].append(line)
            elif linedict['type'] =='CDS':
                tdec_transcript_dict[attribute_dict['Parent']]['cds'].append(line)
            elif linedict['type'] == 'three_prime_UTR':
                tdec_transcript_dict[attribute_dict['Parent']]['three_prime_UTR'].append(line)
            elif linedict['type'] == 'five_prime_UTR':
                tdec_transcript_dict[attribute_dict['Parent']]['five_prime_UTR'].append(line)
            else:
                raise ValueError('{} not a valid stringtie feature type'.format(linedict['type']))

    merge_out = open('{}_wCDSfeatures.gff3'.format(opts.gtf.replace('.gtf','')),'w')
    final_open = open('{}'.format(opts.gtf.replace('gtf','gff3')),'r')
    seen_tdec_genes = set()
    seen_nc_genes = set()
    seen_tdec_transcripts = set()

    for line in final_open:
        if line[0] =='#':
            merge_out.write(line)
        else:
            linedict = dict(zip(fields,line.strip().split('\t')))
            attribute_dict = ParseStringtieAttributes(linedict)
            if linedict['type'] == 'transcript':
                # write gene level protein coding feature
                if attribute_dict['Parent'] in tdec_gene_dict and attribute_dict['Parent'] not in seen_tdec_genes: #first time sees gene id in a transcript
                    merge_out.write('{}\n'.format(re.sub("\\^.*?\\^","",tdec_gene_dict[attribute_dict['Parent']].strip().split('|')[0]).replace('"','').replace('-;',';').split(',score')[0].replace(' ','_').split('(')[0][:-1]))
                    seen_tdec_genes.add(attribute_dict['Parent'])

                # write putative ncRNA gene feature    
                elif attribute_dict['Parent'] not in seen_nc_genes:
                    gene_dict = linedict.copy()
                    gene_dict['type'] = 'gene'
                    gene_dict['start'] = str(gene_interval_dict[attribute_dict['Parent']]['start'])
                    gene_dict['end'] = str(gene_interval_dict[attribute_dict['Parent']]['end'])
                    gene_dict['attributes'] = 'ID={}'.format(attribute_dict['Parent'])
                    merge_out.write('{}\n'.format('\t'.join([gene_dict[field] for field in fields])))
                    seen_nc_genes.add(attribute_dict['Parent']) 
                # write protein coding mRNA and associated child features    
                if attribute_dict['ID'] in tdec_transcript_dict:
                    merge_out.write('{}\n'.format(re.sub("\\^.*?\\^","",tdec_transcript_dict[attribute_dict['ID']]['mRNA'].split('|')[0]).replace('-','').replace('"','').split(',score')[0].replace(' ','_').split('(')[0][:-1]))
                    for utr in tdec_transcript_dict[attribute_dict['ID']]['five_prime_UTR']:
                        merge_out.write(utr)
                    for exon in tdec_transcript_dict[attribute_dict['ID']]['exons']:
                        merge_out.write(exon)
                    for cds in tdec_transcript_dict[attribute_dict['ID']]['cds']:
                        merge_out.write(cds)
                    for utr in tdec_transcript_dict[attribute_dict['ID']]['three_prime_UTR']:
                        merge_out.write(utr)
                    seen_tdec_transcripts.add(attribute_dict['ID'])
                # write putative nc transcript
                else:
                    merge_out.write(line.replace('geneID','Parent'))
                    
            elif linedict['type'] == 'exon':
                if attribute_dict['Parent'] not in seen_tdec_transcripts:
                    merge_out.write(line)

    merge_out.close()
