#!/bin/bash
#==================
# Run the core steps
# for the OpenFOAM
# multihost-MPI-Singularity
# demo.
#
# This script assumes:
# 1. You have access to /contrib/alvaro/ompi
#    (A precompiled OpenMPI library;
#    if not, then use steps 00 and 02 to
#    build your own OpenMPI.)
# 2. You only want to run it to "show it runs"
#    but not generate a longer dataset.
#
#=====================

./step_01_build_container.sh

./step_03_setup_openfoam.sh

sbatch ./step_06_run_openfoam_multihost.sh

