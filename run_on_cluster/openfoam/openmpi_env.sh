# Set persistent environment variables
# for using an OpenMPI installation.

# OPENFOAM_SHARED_DIR is in main_env.sh.
# Access these vars from there instead
# of running directly.

# Some OpenMPI paths
# AWS images have OpenMPI preinstalled
#export OMPI_DIR=/opt/amazon/openmpi
# Custom OpenMPI
export OMPI_DIR=${OPENFOAM_SHARED_DIR}/ompi
export PATH=${OMPI_DIR}/bin:$PATH
export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
export MANPATH=$OMPI_DIR/share/man:$MANPATH

# Done!

