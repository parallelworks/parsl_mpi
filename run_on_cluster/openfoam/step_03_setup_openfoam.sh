#!/bin/bash
#========================
# Get the OpenFOAM files
# that define the "case"
# (exact configuration/scenario
# we want to run).
#
# These files are provided
# in the OpenFOAM container!
#========================

echo "Setting up OpenFOAM cyclone example..."

# Set working directory and go there
RUN_DIR=${HOME}
cd $RUN_DIR

echo "Will work in $RUN_DIR"

# Set OpenFOAM container
SIF_PATH=${HOME}/openfoam.sif

echo "Will use container: $SIF_PATH"

singularity exec ${SIF_PATH} /bin/bash -c "cp -r /opt/openfoam11/tutorials/incompressibleDenseParticleFluid/cyclone ."

# Adjust parameters of the simulation
# You could adjust the number of domains
# and the decomposition in the file
# decomposeParDict.

# Adjust the run time from 7 seconds to
# 0.2 seconds to speed up demo.
cd $RUN_DIR/cyclone/system
mv controlDict controlDict.orig
sed 's/7/0.2/g' controlDict.orig > controlDict

echo "Done setting up run. Adjusted run time from 7s to 0.2 s."
