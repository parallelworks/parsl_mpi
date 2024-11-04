# Set persistent environment variables
# for using an OpenMPI installation.

# Get some base paths
source main_env.sh

# Some OpenMPI paths
export OMPI_DIR=${OPENFOAM_SHARED_DIR}/ompi
export PATH=${OMPI_DIR}/bin:$PATH
export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
export MANPATH=$OMPI_DIR/share/man:$MANPATH

# Done!

