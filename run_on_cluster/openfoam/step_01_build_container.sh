#!/bin/bash
#---------------------
echo "Building container..."
# Container (.sif) is based on defintion file (.def)
sudo singularity build $HOME/openfoam.sif openfoam.def
echo "Done building container."

