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
# An alternative to running it under an scl enable shell
# is to run this command:
source /opt/rh/gcc-toolset-11/enable

# For Spack-stack 1.8.0, need to do a direct install
# of OneAPI since spack-stack1.8.0 is pinned to OneAPI 2024.1.0
# but this segfaults when compiling FMS.
source /opt/intel/oneapi/setvars.sh

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

# JCSDA spack-stack, UFS is probably at 1.5.1
# Works well
#spack_stack_tag=spack-stack-1.5.1
# Move to more recent version for cloud deployment
# Is this tag the same as the other?
#spack_stack_tag=spack-stack-1.8.0
spack_stack_tag='release/1.8.0'
git clone --recurse-submodules -b ${spack_stack_tag} https://github.com/jcsda/spack-stack.git
cd spack-stack
# Sources Spack from submodule and sets ${SPACK_STACK_DIR}
source setup.sh

#==========================================
# Step 3: Connect to a buildcache and compiler
# Note that here we assume you have already exported
# your cloud bucket credentials into environment
# variables to use a bucket-based buildcache.
# You can replace the s3:// URL here with a path
# if using an attached storage based buildcache.
#
# --autopush, --unsigned options may not work with old versions
# of spack-stack/Spack, but could be convenient to
# add here if you can.
#---------------------------------------------
# Standard AWS S3 connection
spack mirror add ufs-cache $BUCKET_URI
#---------------------------------------------
# Try with cunoFS (need to be in cuno shell!)
# Appears to be able to do basic reads like
# spack buildcache list, but package transfers 
# result in seg faults.
#spack mirror add ufs-cache /cuno/s3/$BUCKET_NAME
#--------------------------------------------
spack buildcache list

# Select an Intel compiler
# Although listed in older versions of Spack,
# 2021.1.x, 2021.2.x are not downloadable
# 2021.3.0 is downloadable, but IntelMPI@2021.3.0
# does not appear easily usable since not preferred.
# Stick with IntelMPI@2021.9.0 since that is preferred.
# These worked with spack-stack 1.6.0 but fail with metis in spack-stack 1.8.0
#intel_compiler_ver="2021.3.0"
#intel_mpi_ver="2021.10.0"
# Try updated with spack-stack 1.8.0. 
# Note, this is spack v0.22, so the newest Intel OneAPI versions are:
intel_compiler_ver="2024.2.0"
# But that fails unless you set the compile to oneapi in the packages conf below, so roll back to the most recent version that still has icc, icpc
# Internal compiler error with fms:
#intel_compiler_ver="2023.2.4"
# This is the version on Orion but also doesnot work with fms:
#intel_compiler_ver="2023.1.0"

# Latest in OneAPI but not in spack-stack's pinned repos
intel_mpi_ver="2021.13"

#----------------------------------------
# Do not install OneAPI here - instead it
# is installed on the system level/image.
# Just search for the compilers.
#spack install --no-check-signature intel-oneapi-compilers@${intel_compiler_ver}
#spack load intel-oneapi-compilers
spack compiler find
#spack unload
#----------------------------------------
# Do not install MPI here - instead, it is added the the environment
# and will be installed automatically. Otherwise, it appears to install twice.
#spack install --no-check-signature intel-oneapi-mpi@${intel_mpi_ver}

#=========================================
# Step 4: Create a Spack environment based
# on the existing template provided by
# spack-stack.

# Very out of date?
#template_name="gfs-v16.2"

# Runs but incomplete?
template_name="ufs-weather-model"

# Try everything - long concretize, unavoidable?
#template_name="unified-dev"

# The template's specs are written to 
# spack-stack/envs/envs/${template_name}.mylinux/spack.yaml
# The --compiler flag appears to be required starting on v1.8.0
# Choices are available here: https://spack-stack.readthedocs.io/en/latest/Environments.html
spack stack create env --site linux.default --template ${template_name} --name ${template_name}.mylinux --compiler oneapi
cd envs/${template_name}.mylinux/
spack env activate -p .

# Add intel-oneapi-mpi, this spec is written to
# spack-stack/envs/envs/${template_name}.mylinux/spack.yaml
# REMOVE this b/c using OneAPI MPI as an external package.
#spack add intel-oneapi-mpi@${intel_mpi_ver}

#=========================================
# Step 5: Find external packages
# Use SPACK_SYSTEM_CONFIG_PATH to modify site config
# files in envs/${template_name}.mylinux/site/packages.yaml
# (which is originally blank for linux.default site).
export SPACK_SYSTEM_CONFIG_PATH="$PWD/site"

spack external find --scope system \
    --exclude bison --exclude cmake \
    --exclude curl --exclude openssl \
    --exclude openssh --exclude python

spack external find --scope system wget

# Note - only needed for running JCSDA's
# JEDI-Skylab system (using R2D2 localhost)
spack external find --scope system mysql

# Note - only needed for generating documentation
spack external find --scope system texlive

spack compiler find --scope system

# Done finding external packages, so unset
unset SPACK_SYSTEM_CONFIG_PATH

# Need to add intel-oneapi-mpi to env/<env_name>/sites/packages.yaml
# Normally, you should be able to do this with a spack config command,
# but I'm doing it manually here.
spack_packages="site/packages.yaml"
mpi_path=`dirname $(which mpicc) | cut -d "/" -f 1,2,3,4,5,6`
echo "Adding OneAPI MPI to ${spack_packages} for spack stack setup-meta-modules."
#===============================================
echo "  mpi:" >> $spack_packages
echo "    buildable: False" >> $spack_packages
echo "  intel-oneapi-mpi:" >> $spack_packages
echo "    externals:" >> $spack_packages
echo "    - spec: intel-oneapi-mpi@${intel_mpi_ver}" >> $spack_packages
echo "      prefix: /opt/intel/oneapi" >> $spack_packages
#==============================================

# Set default compiler and MPI library
# This information is going into envs/<env_name>/spack.yaml
# and NOT into envs/<env_name>/sites/packages.yaml.
#
# Need to remove the version specifier on intel-oneapi-mpi?
# Or, looks like Spack is gravitating torwards only IntelMPI@2021.9.0
# but if that's not installed above, fails.
# WORKING HERE: CONSIDER CHANGING 'intel@' to 'oneapi@' if using intel-oneapi-compilers 2024+
spack config add "packages:all:compiler:[oneapi@${intel_compiler_ver}]"
spack config add "packages:all:providers:mpi:[intel-oneapi-mpi@${intel_mpi_ver}]"

# Add the intel-oneapi-mpi as a package, too
# This doesn't work since this goes to spack.yaml
# and you need the package in sites/packages.yaml,
# which is done above in the spack add command.
# Note that here you can specify a variant, for
# example +generic-names if you want mpicc instead
# of mpiicc.
#spack config add "packages:intel-oneapi-mpi@{intel_mpi_ver}"

# Set a few more package variants and versions 
# to avoid linker errors and duplicate packages 
# being built
spack config add "packages:fontconfig:variants:+pic"
spack config add "packages:pixman:variants:+pic"
spack config add "packages:cairo:variants:+pic"

# For JCSDA's JEDI-Skylab experiments using 
# R2D2 with a local MySQL server:
#spack config add "packages:ewok-env:variants:+mysql"

#=====================================
# Step 6: Process the specs and install
# Save the output of concretize in a log file
# so you can inspect that log with show_duplicate_packages.py.
# Duplicate package specifications can cause 
# issues in the module creation step below. 
spack concretize 2>&1 | tee log.concretize
${SPACK_STACK_DIR}/util/show_duplicate_packages.py -d -c log.concretize
spack install --no-check-signature --verbose --fail-fast 2>&1 | tee log.install

# Need to add intel-oneapi-mpi to env/<env_name>/sites/packages.yaml
# Normally, you should be able to do this with a spack config command,
# but I'm doing it manually here.
#mpi_spec=`spack find -p mpi | tail -1 | awk '{print $1}'`
#mpi_path=`spack find -p mpi | tail -1 | awk '{print $2}'`
#spack_packages="site/packages.yaml"
#echo "Detected ${mpi_spec} at ${mpi_path}"
#echo "Adding it to ${spack_packages} for spack stack setup-meta-modules."
#===============================================
#echo "  mpi:" >> $spack_packages
#echo "    buildable: False" >> $spack_packages
#echo "  intel-oneapi-mpi:" >> $spack_packages
#echo "    externals:" >> $spack_packages
#echo "    - spec: intel-oneapi-mpi@${intel_mpi_ver}" >> $spack_packages
#echo "      prefix: $mpi_path" >> $spack_packages
#==============================================

# Create tcl module files (replace tcl with lmod?)
spack module tcl refresh -y

# Create meta-modules for compiler, MPI, Python
spack stack setup-meta-modules

echo "You now have a spack-stack environment" 
echo "that can be accessed by running:"
echo "module use ${SPACK_STACK_DIR}/envs/${template_name}.mylinux/install/modulefiles/Core"
echo "The modules defined here can be loaded" 
echo "to build and run code as described at: "
echo "https://spack-stack.readthedocs.io/en/latest/UsingSpackEnvironments.html#usingspackenvironments"
echo "This script was based on the Linux instructions at: "
echo "https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#newsiteconfigs-linux"

