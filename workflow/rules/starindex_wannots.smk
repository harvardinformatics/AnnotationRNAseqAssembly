def get_star_SAindexNbases(genomefasta):
    genome = open(genomefasta,"r"])
    genome_length = 0
    for line in genome:
        if line[0] != ">":
            genome_length+=(len(line.strip()))
    saindex = int(min(14,log2(genome_length)/2 - 1))
    return saindex


def get_input_stream(file):
    if file[-2:]=='gz':
    filehandle=gzip.open(file,'rb')
    else:
        filehandle=open(file,'r')
    return filehandle

def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args) 

def get_sjdb_overhang(fastq_dir="fastq",maxseqs=5000):
    lengths = [] 
    files = []
    for ext in ("*fq","*fq.gz","*fastq","*fastq.gz"):
        files.extend(glob(join(fastq_dir,ext)))
    for file in files:
        numseqs = 0
        file_stream = get_input_stream(file)
        with file_stream as reads:
            grouped = grouper(file_stream, 4)
            while numseqs <= maxseqs:
                for read in grouped:
                    head,seq,placeholder,qual=[i.decode('ASCII').strip() for i in entry]
                    lengths.append(len(seq))
                    numseqs +=1
    return int(median(lengths) - 1)    
 

    
