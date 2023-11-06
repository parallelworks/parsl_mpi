# Using $HOME because this is accessible on all clusters.
# It is possible to use other shared directories
# if available (e.g. /contrib, /lustre, /bucket)
shared_dir=$HOME

# Set persistent environment variables
export OMPI_DIR=${shared_dir}/ompi
export PATH=${shared_dir}/ompi/bin:$PATH
export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
export MANPATH=$OMPI_DIR/share/man:$MANPATH

# Done!

