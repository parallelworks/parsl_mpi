#!/bin/bash
#==============================
# General build script for Parsl 
# and Flux in Spack.
#
# Please see README.md for how how/why
# to use install_dir, below.
#==============================

install_dir=${HOME}/parsl_flux
#install_dir=/var/lib/pworks

#==============================
echo Install newer version of gcc...
#==============================

sudo yum install -y centos-release-scl
sudo yum install -y devtoolset-7

#==============================
echo Setting up SPACK_ROOT...
#==============================

export SPACK_ROOT=${install_dir}/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod --recursive a+rwx ${install_dir}

#==============================
echo Downloading spack...
#==============================

git clone -b v0.18.0 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

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

pip3 install botocore==1.23.46 boto3==1.20.46

#==============================
echo Configuring external packages...
#==============================

spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
echo "    gcc:" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: gcc@7.3.1" >> $spack_packages
echo "          prefix: /opt/rh/devtoolset-7/root/usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages
echo "    slurm:" >> $spack_packages
echo "        variants: +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: slurm@20.02.7 +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "          prefix: /usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages

#==============================
echo Installing spack packages...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
echo 'source ~/.bashrc; \
spack compiler find; \
spack install -j 30 patchelf; \
spack compiler find; \
spack unload; \
spack install -j 30 openmpi; \
spack install -j 30 flux-sched; \
spack install -j 30 miniconda3' | scl enable devtoolset-7 bash

#==============================
echo Install Parsl in Spack Miniconda
#==============================
spack load miniconda3
conda install -c conda-forge parsl
conda install sqlalchemy
conda install sqlalchemy-utils
pip install parsl[monitoring]

#==============================
echo Install local Miniconda...
#==============================
#miniconda_loc=${install_dir}/miniconda
#wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh
#chmod u+x Miniconda3-py39_4.9.2-Linux-x86_64.sh
#./Miniconda3-py39_4.9.2-Linux-x86_64.sh -b -p $miniconda_loc
#rm -f Miniconda3-py39_4.9.2-Linux-x86_64.sh

# (Do not run conda init as part of install)
#source ${miniconda_loc}/etc/profile.d/conda.sh
#conda create --name parsl_py39
#conda activate parsl_py39

# Install Pyferret first because its installer
# searches only for a Python version x.x and
# breaks when Pyton is 3.10 or more because it
# thinks the system is at Python 3.1.
#conda install -y -c conda-forge pyferret
#conda install -y -c conda-forge parsl
#conda install -y requests
#conda install -y ipykernel
#conda install -y -c anaconda jinja2

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

echo Completed building image
# It is essential to have a newline at the end of this file!

