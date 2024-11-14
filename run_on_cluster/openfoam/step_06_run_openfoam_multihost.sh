#!/bin/bash
#=================================
# Run OpenFOAM based on the 
# specifications in the environment
# files.
#=================================

#=================================
# Source environment
#=================================
echo 'Starting OpenFOAM run...'
echo "Currently in ${PWD}"
source main_env.sh

RUN_DIR="${OPENFOAM_SHARED_DIR}/cyclone"
cd $RUN_DIR

#=================================
# Create launch script
#=================================
cat > slurm-singularity-openfoam.sh << EOF
#!/bin/bash

#SBATCH --nodes=${NNODES}
#SBATCH --job-name=singularity-openfoam
#SBATCH --output=singularity-openfoam-%J.%t.out
#SBATCH --ntasks-per-node=${NTASKS_PER_NODE}
#SBATCH --cpus-per-task=1

#export OMP_NUM_THREAD=${NTASKS_PER_NODE}
#export OMP_WAIT_POLICY=ACTIVE

# LOAD OpenMPI ENVIRONMENT HERE!
# This is the OpenMPI env if installed
# with step_02_install_openmpi.sh
source $HOME/parsl_mpi/run_on_cluster/openfoam/main_env.sh
# This is OpenMPI env if using Alvaro's
# preinstalled build.
#source /contrib/alvaro/ompi/env.sh

# Spit out the uncommented lines of the OpenFOAM
# definition file used in the above command.
echo "Getting OpenFOAM configuration..."
cat $HOME/parsl_mpi/run_on_cluster/openfoam/openfoam_env.sh | grep -v \# | tr "\n" ","

# SET RUN DIR (same as #SBATCH --chdir=/path/to/OpenFOAM/case(
cd $RUN_DIR

# REPLACE THE PATH TO THE SIF FILE
SIF_PATH="${OPENFOAM_SHARED_DIR}/openfoam.sif"

# SET NUMBER OF MPI PROCESSES = OPENFOAM SUBDOMAINS
# 12 is the default value in cyclone/system/decomposeParDict
# Note that the number of nodes and ntasks-per-node
# set above need to multiply to 12 (e.g. 6 nodes
# with 2 CPU each => 2 x 6 = 12).
#num_mpi_proc=${NPROCS_MPI}

set -x
ulimit -s unlimited
ulimit -a

# MESH CASE
singularity exec \${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; blockMesh"
singularity exec \${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; snappyHexMesh -overwrite"
singularity exec \${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; decomposePar"


# RUN SIMULATION
# Launch for OpenMPI - verbose!
#mpiexec --mca btl_tcp_if_include eth0 --mca btl_base_verbose 100 --mca orte_base_help_aggregate 0 -np ${NPROCS_MPI} singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; foamRun -parallel"

# Launch for OpenMPI

# GCP --mca btl_tcp_if_include eth0
time mpiexec --mca btl_tcp_if_include eth0 -np \$SLURM_NTASKS singularity exec \$SIF_PATH /bin/bash -c "source /opt/openfoam11/etc/bashrc; foamRun -parallel"

# AWS --mca


# AZU --mca btl_openib_allow_ib true --mca btl vader,self,openib
#time mpiexec --mca btl_openib_allow_ib true --mca btl vader,self,openib -np \$SLURM_NTASKS singularity exec \$SIF_PATH /bin/bash -c "source /opt/openfoam11/etc/bashrc; foamRun -parallel"

#==========================================
# Launch for OneAPI MPI
# Neither mpiexec or mpirun run this way

#export I_MPI_DEBUG=6
#export I_MPI_FABRICS=shm:ofi
#mpiexec --np $NPROCS_MPI --ppn $NTASKS_PER_NODE singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; export I_MPI_FABRICS=shm:ofi; foamRun -parallel"

# Try what works for WRF:
# Nope...
#mpiexec.hydra -np $NPROCS_MPI --ppn $NTASKS_PER_NODE singularity exec ${SIF_PATH} /bin/bash -c "source /opt/openfoam11/etc/bashrc; foamRun -parallel"
# Example from Intel docs:
#https://www.intel.com/content/www/us/en/docs/mpi-library/developer-guide-windows/2021-6/run-the-application-with-a-container.html
#mpiexec -np $NPROCS_MPI hostname
#singularity shell ${SIF_PATH} hostname
#singularity shell ${SIF_PATH} /bin/bash -c "spack load intel-oneapi-mpi; which mpiexec"
# End of failing attempts
#==========================================

echo $? > openfoam.exit.code
EOF

#=============================
# Run it!
#=============================
echo; echo "Running sbatch slurm-singularity-openfoam.sh from ${PWD}..."
sbatch slurm-singularity-openfoam.sh

#=============================
# Clean up
#=============================

#rm -f slurm-singularity-openfoam.sh

# ADD FOAM FILE for Paraview
touch out.foam

