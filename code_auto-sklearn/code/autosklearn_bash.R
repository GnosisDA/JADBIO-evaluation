# function for writing the bash script for autosklearn on a slurm system
autosklearn_bash <- function(bashFile, a, b, cTime, n, mem){

  # bashFile: file to write
  # a: training_set
  # b: test_set
  # cTime: time_left_for_this_task (seconds, total time)
  # n: n_processes
    
  # opening the bash file
  sink(file = bashFile, append = FALSE, 
       type = 'output', split = FALSE)
  
  # standard part
  cat('#!/bin/bash

####################################
#     ARIS slurm script template   #
#                                  #
# Submit script: sbatch filename   #
#                                  #
####################################

#SBATCH --job-name=',sub(pattern = '_', replacement = '', x = a, fixed = TRUE),'   # Job name
#SBATCH --output=',sub(pattern = '_', replacement = '', x = a, fixed = TRUE),'.out # Stdout 
#SBATCH --error=',sub(pattern = '_', replacement = '', x = a, fixed = TRUE),'.err # Stderr 
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --cpus-per-task=20     # Threads per task
#SBATCH --time=',max(c(floor(2*cTime/3600),1)),':00:00   # walltime
#SBATCH --mem=',mem,'G   # memory per NODE
#SBATCH --partition=taskp    # Partition
#SBATCH --account=vspr003006 #pa180501    # Accounting project

export I_MPI_FABRICS=shm:dapl

if [ x$SLURM_CPUS_PER_TASK == x ]; then
export OMP_NUM_THREADS=1
else
  export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
fi

export OPENBLAS_NUM_THREADS=1

## LOAD MODULES ##
module purge		# clean up loaded modules 

# load necessary modules
module load gnu/4.9.2
module load intel/15.0.3
module load intelmpi/5.0.3
module load python/3.6.5

', sep = '')
  
  # customized part
  cat('## RUN YOUR PROGRAM ##
srun python python_script_JAD_paper.py -a ', a,' -b ', b, ' -t ', cTime, ' -n ', n, '

', sep = '')
  
  # closing the bash file
  sink()
  
}
