#!/bin/bash
#==============================
# General cluster setup script 
# reusing a Spack environment 
# for Parsl and Flux in Spack.
#
# This script assumes you have
# already run step_01a_install_with_Spack.sh
# and then saved a tarball of the
# resulting Spack environment
# somewhere off the cluster
# and then shut the cluster down.
# Here, I assume the tarball
# has been saved to /contrib,
# but it could be rsynced
# from elsewhere, too.
#==============================

# Assume same install dir as in Step 1.
install_dir=${HOME}/parsl_flux
#install_dir=/var/lib/pworks

#==============================
echo Setting up SPACK_ROOT...
#==============================

export SPACK_ROOT=${install_dir}/spack

#==============================
echo Copying and decompressing Spack archive 10 mins...
#==============================

spack_archive=/contrib/sfgary/parsl_flux_6.tar.gz
cp $spack_archive /home/sfgary/
cd /home/sfgary
tar -xzf $(basename $spack_archive)

#==============================
echo Set up Spack environment 1 min...
#==============================

# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
sudo -s eval echo export SPACK_ROOT=${SPACK_ROOT}" >> "/etc/bashrc
sudo -s eval echo source ${SPACK_ROOT}/share/spack/setup-env.sh" >> "/etc/bashrc
source $HOME/.bashrc

#==============================
echo Install some dependencies to check download certificates 1 min...
#==============================

#pip3 install botocore==1.23.46 boto3==1.20.46
pip3 install botocore
pip3 install boto3

#==============================
echo Find compilers 1 min...
#==============================
spack load gcc@12.2.0
spack compiler find
spack unload

#==============================
echo Install SLURM-devel 1 min...
#==============================
# Temporary fix for current Latest version
# of PW cloud cluster images
./step_00a__install_slurm-devel.sh

#==============================
echo Install OpenMPI outside Spack 10 mins...
#==============================
./step_00b__install_openmpi_no_Spack.sh

echo Completed redeploying Spack

