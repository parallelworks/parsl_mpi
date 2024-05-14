#! /bin/bash
#========================
# Build it
# This script assumes you
# have started/sourced
# the spack-stack build
# environment with
# step_04_...
#========================

# This is a manual approach - you can
# also use the rt.conf file
# to orchestrate a series of configuration
# builds and tests as described here:
#https://ufs-weather-model.readthedocs.io/en/develop/BuildingAndRunning.html#using-the-regression-test-script

# Change to $HOME just in case (don't
# want to put build repo in other git
# repo.)
cd $HOME

# Get UFS base model
git clone --recursive https://github.com/ufs-community/ufs-weather-model.git ufs-weather-model
cd ufs-weather-model
# Which config do you want?
# Atmosphere only
export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"
# Atmosphere coupled to Wave Watch III
# CMEPS coupler cannot find MPI on compile -> will impact all others
#export CMAKE_FLAGS="-DAPP=ATMW -DCCPP_SUITES=FV3_GFS_v16"
./build.sh

# Get UFS global workflow
#git clone --recursive -b wei-epic-gcp https://github.com/NOAA-EPIC/global-workflow-cloud

