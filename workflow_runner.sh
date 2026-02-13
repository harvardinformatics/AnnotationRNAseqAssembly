#!/bin/bash
#SBATCH -J snaketest
#SBATCH -n 1                 
#SBATCH -t 72:00:00        
#SBATCH -p sapphire,shared    
#SBATCH --mem=2000           
#SBATCH -o logs/test.%A.out  
#SBATCH -e logs/test.%A.err  

module purge
module load python
conda activate snakemake

conda_prefix=$1 # where to install conda environments, useful to avoid filling up home directory
global_snakemake_profile=$2 # this is the name of the directory for your global snakemake profile  that is usually a subdirectory in  $HOME/.config/snakemake/

snakemake --unlock --snakefile workflow/Snakefile --configfile config/config.yaml --use-conda --workflow-profile profiles/slurm --profile $global_snakemake_profile

snakemake --conda-prefix $conda_prefix --snakefile workflow/Snakefile --configfile config/config.yaml --use-conda --workflow-profile profiles/slurm --profile cannon



