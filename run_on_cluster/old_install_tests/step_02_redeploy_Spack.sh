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
echo Copying and decompressing Spack archive...
#==============================

spack_archive=/contrib/sfgary/parsl_flux_2.tar.gz
cp $spack_archive /home/sfgary/
cd /home/sfgary
tar -xzf $(basename $spack_archive)

#==============================
echo Set up Spack environment...
#==============================

# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
sudo -s eval echo export SPACK_ROOT=${SPACK_ROOT}" >> "/etc/bashrc
sudo -s eval echo source ${SPACK_ROOT}/share/spack/setup-env.sh" >> "/etc/bashrc
source $HOME/.bashrc

#==============================
echo Install some dependencies to check download certificates...
#==============================

#pip3 install botocore==1.23.46 boto3==1.20.46
pip3 install botocore
pip3 install boto3

echo Completed redeploying Spack

