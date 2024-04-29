#! /bin/bash
#=====================================
# Install spack-stack for use with UFS
#
# Run this script in a gcc-toolset-11
# enabled bash shell to access gcc11,
# i.e.:
#
# scl enable gcc-toolset-11 bash
# ./step_02_spack-stack.sh
#
# Based on the instructions at:
# https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#newsiteconfigs-linux
#=====================================

# Download Spack, start it, and add the buildcache
# mirror to Spack.

#==========================================
# Step 1: Where do you want to put Spack?

# Default location for spack-stack?
#spack_dir=/contrib/spack-stack/spack-stack-1.6.0

# Try $HOME for now...
spack_dir=${HOME}/spack

#===========================================
# Step 2: Grab Spack

mkdir -p $spack_dir
cd $spack_dir

# Standard spack
#git clone -c feature.manyFiles=true https://github.com/spack/spack.git
# source ${PWD}/spack/share/spack/setup-env.sh

# JCSDA spack-stack
git clone --recurse-submodules https://github.com/jcsda/spack-stack.git
cd spack-stack
# Sources Spack from submodule and sets ${SPACK_STACK_DIR}
source setup.sh

#==========================================
# Step 3: Connect to a buildcache
# Note that here we assume you have already exported
# your cloud bucket credentials into environment
# variables to use a bucket-based buildcache.
# You can replace the s3:// URL here with a path
# if using an attached storage based buildcache.
spack mirror add aws-mirror s3://$BUCKET_NAME
spack compiler find
spack buildcache list

