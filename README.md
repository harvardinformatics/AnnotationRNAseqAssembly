# AnnotationRNAseqAssembly
This repository consists of a Snakemake workflow to produce a CDS-annotated genome annotation using [Stringtie](https://github.com/gpertea/stringtie) and [TransDecoder](https://github.com/TransDecoder/TransDecoder). It consists of the following steps:

* Build a STAR aligner index for the genome if it doesn't already exist
* Perform 2-pass STAR alignment of provided paired-end RNA-seq reads to the genome
* Assembles transcripts from those alignments with Stringtie
* Predicts CDS and UTR features for the annotation with TransDecoder
* Adds back into the TransDecoder annotation those features for which open reading framers(ORFs) could not be found
  * TransDecoder normally discards things w/o detectable ORFs which we view as being less than ideal, so we fix that


To run the workflow, you need to create a directory called *data* directory within the workflow base directory that contains three subdirectories:

* **fastq**: contains the paired-end RNA-seq fastq files
* **genome**: contains the genome fasta, and a STAR index if already generated
* **blast**: this should be a protein blast database that predicted ORFs can be searched against. This is necessary to invoke a TransDecoder feature that, when selecting from a set of candidate ORFs, has TransDecoder prefer an ORF with a blastp hit over one that doesn't. 

You then need to:
* edit *sampletable.tsv* so it specifies your sample ids, and the full path names of the R1 and R2 fastq files for each sample. Note, if you wish to point to RNA-seq fastq files to a different location other than *data/fastq*, you need to do it in the sample sheet, in which case creating the *data/fastq* directory will not be necessary.
* edit *config/config.yaml*, especially if you are already supplying a STAR index--therefore need to indicate its location, and set *StarIndexExists* to TRUE, but you also need to supply the genome fasta file name (assuming it resides in  *data/genome*), and the prefix of the files in the protein blast database.
* if you are running the workflow on an HPC cluster, you will need to specify slurm partition names in *profiles/slurm/config.yaml*.
 
Note that the yaml file in *profiles/slurm* is a workflow-specific profile that sets resources related to rules that are used to execute particular workflow steps. This is distinct from a global profile, which sets options for the cluster environment in which the workflow is being executed. On a linux system, one's global profile will typically located in your home directory, e.g. `$HOME/.config/snakemake`. An example global profile for a cluster running SLURM might look like this, and would be called, somewhat confusingly, *config.yaml*: 

```bash
executor: slurm
use-conda: True
jobs: 100
latency-wait: 100
retries: 0


default-resources:
    slurm_account: "" # add your account here
    slurm_partition: "" # add your partition list here
    runtime: 360 
    mem_mb: 6000
    threads: 1
```

If you do not need to modify a global profile from the defaults, then all that is needed is to specify the workflow profile.In this case, you can then execute the Snakemake worflow as follows:

```bash
snakemake --snakefile workflow/Snakefile --workflow-profile ./profiles/slurm
```

If you also needed to specify a particular global profile, if you put the global profile yaml file in a directory called `my_global` and placed that directory in `$HOME/.config/snakemake/`, you could then specify both the local and the qworkflow-specific profile like this:


```bash
snakemake --snakefile workflow/Snakefile --workflow-profile ./profiles/slurm --profile my_global
```

For more information on global and workflow profiles consult the [Snakemake profiles documentation](https://snakemake.readthedocs.io/en/stable/executing/cli.html#executing-profiles).

With either of these options, the command can easily be wrapped as a cluster submission job. As it simply manages conda package installs, submission of cluster data analysis jobs, and runs some low-memory serial jobs for file conversions, it can be submitted with one core, and with a modest amount of memory, e.g. a few Gb.


