#!/bin/bash
#===========================
# Download Miniconda, install,
# and create a new environment
# for using Parsl with MPI.
#
# Specify the Conda install location
# and environment name in the 
# script below. Run script on
# command like, e.g.
#
# ./create_conda_env.sh
#
# With a fast internet connection
# (i.e. download time minimal)
# this process takes < 5 min.
#
# For moving conda envs around,
# it is possible to put the
# miniconda directory in a tarball
# but the paths will need to be
# adjusted.  The download and
# decompression time can be long.
# As an alternative, consider:
# conda list -e > requirements.txt
# to export a list of the req's
# and then:
# conda create --name <env> --file requirements.txt
# to build another env elsewhere.
# This second step runs faster
# than this script because
# Conda does not stop to solve
# the environment.  Rather, it
# just pulls all the listed
# packages assuming everything
# is compatible.
#===========================

echo Starting $0

# Miniconda install location
# The `source` command somehow
# doesn't work with "~", so best
# to put an absolute path here
# or at least use $HOME instead 
# of "~".
miniconda_loc=$HOME/pw/miniconda3

# Download current version of
# Miniconda installer
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Run Miniconda installer
chmod u+x ./Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -b -p $miniconda_loc

# Clean up
rm ./Miniconda3-latest-Linux-x86_64.sh

# Define environment name
my_env=parsl-mpi

# Start conda
source ${miniconda_loc}/etc/profile.d/conda.sh
conda activate base

# Create new environment
# (if we are running Jupter notebooks, include ipython here)
#conda create -y --name $my_env python${python_version}
conda create -y --name $my_env

# Jump into new environment
conda activate $my_env

# Install packages
conda install -y -c conda-forge parsl
conda install -y sqlalchemy
conda install -y sqlalchemy-utils

# Pip packages last
# SMOGN on pip does not allow for seed option.  Use dev.
pip install parsl[monitoring]

echo Finished $0

