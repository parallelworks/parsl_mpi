#!/bin/bash
#---------------------
echo "Sourcing environment..."
source openmpi_env.sh

echo "Building container..."
# Container (.sif) is based on defintion file (.def)
sudo singularity build ${OPENFOAM_SHARED_DIR}/openfoam.sif openfoam.def
echo "Done building container."

