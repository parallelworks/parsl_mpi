#!/bin/bash
#==============================
# General build script for Parsl 
# and Flux in Spack.
#
# Please see README.md for how how/why
# to use install_dir, below.
#==============================

#install_dir=/scratch/sfg3866/flux
install_dir=${HOME}/parsl_flux
#install_dir=/var/lib/pworks

#==============================
echo Setting up SPACK_ROOT...
#==============================

export SPACK_ROOT=${install_dir}/spack
mkdir -p $SPACK_ROOT
#chmod --recursive a+rwx ${install_dir}
cd $SPACK_ROOT

#==============================
echo Downloading spack...
#==============================

# --depth shortens the history contained in the clone
# --branch selects a specific release, UPDATE THIS
git clone --depth=100 --branch=releases/v0.19 https://github.com/spack/spack.git $SPACK_ROOT

#==============================
echo Set up Spack environment...
#==============================

# An alternative for local testing is $HOME/.bashrc
# If these lines are added to /etc/bashrc, it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
echo export SPACK_ROOT=${SPACK_ROOT} >> $HOME/.bashrc
echo source ${SPACK_ROOT}/share/spack/setup-env.sh >> $HOME/.bashrc
source $HOME/.bashrc

#==============================
echo Install some dependencies to check download certificates...
#==============================

#pip3 install botocore==1.23.46 boto3==1.20.46
pip3 install botocore
pip3 install boto3

#==============================
echo Configuring external packages for Spack...
#==============================
# Examples here:
# https://spack.readthedocs.io/en/latest/getting_started.html#system-packages
# More detail here:
# https://spack.readthedocs.io/en/latest/build_settings.html

# Notes:
# 1) Do we want/need to use the existing SLURM installation
#    to tell Spack that this SLURM has
#    PMIX enabled (test with `srun --mpi=list`)?
#    It looks like this is not required.
# 2) Do we want/need to require any OpenMPI to be installed
#    with PMI support? Even if you require this
#    as a dependency when installing Flux later, e.g.
#    spack install flux-sched ^openmpi+pmi ^slurm+pmix
#    the install process will install its own openmpi
#    that does NOT have have PMI support unless the
#    Spack packages.yaml has require: +pmi.

echo For now, skipping any Spack external package config!
# I get the same errors whether or not I include OpenMPI.
spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
echo "  slurm:" >> $spack_packages
echo "    externals:" >> $spack_packages
echo "    - spec: slurm@20.02.7 +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "      prefix: /usr" >> $spack_packages
echo "    buildable: False" >> $spack_packages
#echo "  openmpi:" >> $spack_packages
#echo "    require: +pmi" >> $spack_packages

#==============================
echo Installing spack packages...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.

# Different compilers have different issues:
# gcc@4.8.5:
# mbedtls requires gcc -std=c99. This is achieved with:
# spack install mbedtls@2.28.0 cflags=="-std=c99", however,
# even when I specify the package cflags recursively
# (e.g. spack install flux-sched cflags=="-std=c99" , need 
# space at the end) or specify the hash of the successfully
# built mbedtls, installing flux-core/sched still fails.
#
# gcc@12.2.0:
# spack install flux-core%gcc@12.2.0
# compiles flux-sched. Using --test all or --test root
# fails due to what appears to be compiler flag issues. 
# One downside is it takes an
# extra ~22 minutes (on 8 CPU) to compile the compiler itself.
# Also, hwloc (sometimes?) does not compile because missing OpenMPI. So,
# also need to:
# spack install openmpi%gcc@12.2.0+pmi
# (when then installs hwloc as part of openmpi!)
# Note SLURM has +pmix, OpenMPI has +pmi
# spack install flux-sched%gcc@12.2.0  ^openmpi%gcc@12.2.0+pmi ^slurm+pmix
# Then, we can test the OpenMPI+PMI+SLURM installation
# with:
# spack load openmpi%gcc@12.2.0+pmi
# mpicc <test_code>
# srun -N 2 -n 4 -p small test_code.out

# intel-oneapi
# I have not gotten this compiler to build flux-core 
# end-to-end. It fails on mbedtls as well as other
# packages.

echo 'source ~/.bashrc; \
spack install -j 30 gcc@12.2.0; \
spack load gcc@12.2.0; \
spack compiler find; \
spack unload; \
spack install -j 30 flux-core@0.51.0%gcc@12.2.0; \
spack install -j 30 flux-sched%gcc@12.2.0; \
spack install intel-oneapi-compilers@2021.1.2; \
spack load intel-oneapi-compilers; \
spack compiler find; \
spack install -j 30 intel-oneapi-mpi%oneapi;' | /bin/bash

# Alternatives - removed while I check whether forcing
# pmi on openmpi is a good idea. I get the same PMIX/orte/MPI
# init errors either way. None of these OpenMPI versions seem
# to work out-of-the-box with Flux. Only Intel-MPI appears to
# work out of the box.
#spack install -j 30 openmpi@4.1.4%gcc@12.2.0 +pmi; \
#spack install -j 30 openmpi@4.1.4%gcc@12.2.0 -pmi;' | /bin/bash
#spack install -j 30 openmpi%gcc@12.2.0+pmi ^slurm+pmix; \
#spack install -j 30 flux-sched%gcc@12.2.0 ^openmpi+pmi ^slurm+pmix;' | /bin/bash
#spack install -j 30 flux-sched cflags=="-std=c99" ^openmpi+pmi ^slurm+pmix;' | /bin/bash

# DO NOT INSTALL PARSL IN SPACK MINICONDA!
# Flux-in-Spack installs its own Python.
# Install Parsl in the Python installed
# with Flux so that Parsl is (implicitly) 
# present with all the Flux dependencies
# in Python.
#==============================
#echo Install Parsl in Spack Miniconda...
#==============================
#source $HOME/.bashrc
#spack install miniconda3
#spack load miniconda3
#conda install -y -c conda-forge parsl
#conda install -y sqlalchemy
#conda install -y sqlalchemy-utils
#pip install "parsl[monitoring]"

#============================
echo Install Parsl...
#============================
source $HOME/.bashrc
spack load flux-sched
pip install "parsl[monitoring]==2023.9.11"

#==============================
echo Set permissions if in a shared directory...
#==============================
#sudo chmod --recursive a+rwx $install_dir

echo Completed building image

