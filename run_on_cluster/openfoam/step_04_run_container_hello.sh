#!/bin/bash
#SBATCH --nodes=6
#SBATCH --job-name=test-singularity-mpi
#SBATCH --output=test-singularity-mpi.out
#SBATCH --ntasks-per-node=2
#SBATCH --partition=small

# LOAD OpenMPI ENVIRONMENT HERE!
# This is the OpenMPI env if installed
# with step_02_install_openmpi.sh
#source $HOME/parsl_mpi/run_on_cluster/openfoam/openmpi_env.sh
# This is OpenMPI env if using Alvaro's
# preinstalled build.
source /contrib/alvaro/ompi/env.sh

# SET RUN DIR (same as #SBATCH --chdir=/path/to/OpenFOAM/case(
RUN_DIR="$HOME"
cd $RUN_DIR

# REPLACE THE PATH TO THE SIF FILE
SIF_PATH="$HOME/openfoam.sif"

# SET NUMBER OF MPI PROCESSES
# The max value is nodes x ntasks-per-node
num_mpi_proc=12

# Compile
mpicc ${RUN_DIR}/parsl_mpi/mpitest.c

# RUN SIMULATION
mpirun -np ${num_mpi_proc} singularity exec ${SIF_PATH} /bin/bash -c "./a.out"

# Forget the container entirely
#mpirun -np ${num_mpi_proc} ./a.out

# CLEAN UP
#rm a.out

