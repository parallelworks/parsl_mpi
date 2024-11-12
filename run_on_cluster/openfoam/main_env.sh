# Set persistent environment variables
# for using an OpenMPI installation.

# Using $HOME because this is accessible on all clusters.
# It is possible to use other shared directories
# if available (e.g. /contrib, /lustre, /bucket)
#
#shared_dir=$HOME
#
# Custom shared attached storage:
export OPENFOAM_SHARED_DIR=/openfoam

#=====================================
# Select which MPI to use
# Pick ONE of the lines below
#=====================================
#
# Custom OpenMPI installed locally
# (You will normally need to build it yourself!)
source ${HOME}/parsl_mpi/run_on_cluster/openfoam/openmpi_env.sh
#
# Use this if you install Intel OneAPI directly
# to the system, e.g. sudo yum install intel-hpckit
# source /opt/intel/oneapi/setvars.sh
#
# Use this if you want to use IntelMPI from a
# Spack installation. The path here assumes you
# have already defined a SPACK_ROOT (e.g. in your 
# ~/.bashrc).
# This source line should be already in /etc/bashrc
#source ${SPACK_ROOT}/share/spack/setup-env.sh
# So you already have direct access to MPI in Spack:
#spack load intel-oneapi-mpi

#=====================================
# Specify the configuration of OpenFOAM
#=====================================
source ${HOME}/parsl_mpi/run_on_cluster/openfoam/openfoam_env.sh

# Done!

