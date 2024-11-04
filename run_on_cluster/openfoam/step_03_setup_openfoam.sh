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

echo "Sourcing environment..."
source main_env.sh

echo "Setting up OpenFOAM cyclone example..."

# Set working directory and go there
RUN_DIR=${OPENFOAM_SHARED_DIR}
mkdir -p ${RUN_DIR}
cd ${RUN_DIR}

echo "Will work in $RUN_DIR"

# Set OpenFOAM container
SIF_PATH=${OPENFOAM_SHARED_DIR}/openfoam.sif

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
sed "s/7/${RUN_TIME}/g" controlDict.orig > controlDict

# Adjust the domain decomposition for
# the number of processes we can run
cd $RUN_DIR/cyclone/system
mv decomposeParDict decomposeParDict.orig
sed "s/12/${NPROCS_MPI}/g" decomposeParDict.orig > decomposeParDict.tmp
sed "s/(2 2 3)/${DOMAIN_DECOMP}/g" decomposeParDict.tmp > decomposeParDict

echo "Adjusted run time from 7s to ${RUN_TIME} s."
echo "Adjusted number of processes from 12 to ${NPROCS_MPI}."
echo "Adjusted domain decomposition from (2 2 3) to ${DOMAIN_DECOMP}."
echo "Done setting up run."
