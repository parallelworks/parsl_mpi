#!/bin/bash
#========================
# Launcher-wrapper for
# starting sbatch scripts
# and overriding #SBATCH
# options in the scripts
# (default values for testing,
# etc.) with customized
# values in openmpi_env.sh
#
# Usage:
# launcher.sh step_06_run_openfoam_multihost.sh
#=======================

# Get the environment info we want
source openmpi_env.sh

sbatch --ntasks-per-node=${NTASKS_PER_NODE} --exclusive --nodes=${NNODES} $1

