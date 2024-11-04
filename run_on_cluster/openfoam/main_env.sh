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

# Select whether to use OpenMPI or IntelMPI
# Pick ONE of the lines below
source ${HOME}/parsl_mpi/run_on_cluster/openfoam/openmpi_env.sh
#source /opt/intel/oneapi/setvars.sh

# Specify the configuration of OpenFOAM
source openfoam_env.sh

# Done!

