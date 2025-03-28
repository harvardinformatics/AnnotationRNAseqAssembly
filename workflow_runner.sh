#!/bin/bash
#SBATCH -J snaketest
#SBATCH -n 1                 
#SBATCH -t 72:00:00        
#SBATCH -p "" # add the partition here      
#SBATCH --mem=2000           
#SBATCH -o logs/test.%A.out  
#SBATCH -e logs/test.%A.err  

module purge
module load python
mamba activate snakemake_py311

global_profile=$1 # full path to directory where global config.yaml lives, e.g. <your home dir>/.config/snakemake/cannon/

snakemake -p --snakefile workflow/Snakefile --use-conda --profile $global_profile --workflow-profile ./profiles/slurm



