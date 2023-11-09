#!/bin/bash
#SBATCH --nodes=6
#SBATCH --job-name=singularity-openfoam
#SBATCH --output=singularity-openfoam.out
#SBATCH --ntasks-per-node=2

# LOAD OpenMPI ENVIRONMENT HERE!
# This is the OpenMPI env if installed
# with step_02_install_openmpi.sh
#source $HOME/parsl_mpi/run_on_cluster/openfoam/openmpi_env.sh
# This is OpenMPI env if using Alvaro's
# preinstalled build.
source /contrib/alvaro/ompi/env.sh

# SET RUN DIR (same as #SBATCH --chdir=/path/to/OpenFOAM/case(
RUN_DIR="$HOME/cyclone"
cd $RUN_DIR

# REPLACE THE PATH TO THE SIF FILE
SIF_PATH="$HOME/openfoam.sif"

# SET NUMBER OF MPI PROCESSES = OPENFOAM SUBDOMAINS
# 12 is the default value in cyclone/system/decomposeParDict
# Note that the number of nodes and ntasks-per-node
# set above need to multiply to 12 (e.g. 6 nodes
# with 2 CPU each => 2 x 6 = 12).
num_mpi_proc=12

# MESH CASE
singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; blockMesh"
singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; snappyHexMesh -overwrite"
singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; decomposePar"


# RUN SIMULATION
mpiexec --mca btl_tcp_if_include eth0 --mca btl_base_verbose 100 --mca orte_base_help_aggregate 0 -np ${num_mpi_proc} singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; foamRun -parallel"

# ADD FOAM FILE for Paraview
touch out.foam

