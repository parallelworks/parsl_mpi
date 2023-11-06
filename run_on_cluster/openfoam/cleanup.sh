#!/bin/bash
#======================
# Clean up all files
# created while running
# these scripts so
# temporary files are not
# committed to GitHub.
#======================

# Container
rm -f openfoam.sif

# Log files
rm test-singularity-mpi.out
rm singularity-openfoam.out

