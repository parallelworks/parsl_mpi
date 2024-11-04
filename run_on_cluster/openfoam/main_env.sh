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

# Done!

