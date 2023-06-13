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
echo Setting up SPACK_ROOT...
#==============================

export SPACK_ROOT=${install_dir}/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod --recursive a+rwx ${install_dir}
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

#==============================
echo Configuring external packages for Spack...
#==============================
# Examples here:
# https://spack.readthedocs.io/en/latest/getting_started.html#system-packages
# More detail here:
# https://spack.readthedocs.io/en/latest/build_settings.html

# Notes:
# 1) We want to use the existing SLURM installation
#    and we want to tell Spack that this SLURM has
#    PMIX enabled (test with `srun --mpi=list`)
# 2) We want to require any OpenMPI to be installed
#    with PMI support. Even if you require this
#    as a dependency when installing Flux later, e.g.
#    spack install flux-sched ^openmpi+pmi ^slurm+pmix
#    the install process will install its own openmpi
#    that does NOT have have PMI support.
# 3) For cloud clusters, compiling your own OpenMPI is
#    relatively robust (in or out of Spack).

spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
#echo "  gcc:" >> $spack_packages
#echo "    externals:" >> $spack_packages
#echo "    - spec: gcc@7.3.1" >> $spack_packages
#echo "      prefix: /opt/rh/devtoolset-7/root/usr" >> $spack_packages
#echo "    buildable: False" >> $spack_packages
echo "  slurm:" >> $spack_packages
echo "    externals:" >> $spack_packages
echo "    - spec: slurm@20.02.7 +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "      prefix: /usr" >> $spack_packages
echo "    buildable: False" >> $spack_packages
echo "  openmpi:" >> $spack_packages
echo "    require: +pmi" >> $spack_packages
#echo "    externals:" >> $spack_packages
#echo "    - spec: openmpi@$OMPI_VERSION%gcc@$gcc_version +pmi schedulers=slurm" >> $spack_packages
#echo "      prefix: $OMPI_DIR" >> $spack_packages
#echo "    buildable: False" >> $spack_packages

#==============================
echo Installing spack packages...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
#
# Note that this session first finds the
# default system gcc (v4) and then installs,
# loads and finds Spack preferred gcc (v12).
# Because the loaded gcc12 is NOT unloaded
# after it is found, gcc12 
# is used for subsequent build ops as the
# (implicitly) default compiler. Several 
# packages are compiled TWICE, once for the 
# system gcc during the initial bootstrap of
# gcc12 and once for when gcc12 installed in 
# Spack crunches through all the dependencies
# of subsquent packages.
spack_gcc_version=12.2.0

#spack install -j 30 gcc@$spack_gcc_version; \
#spack load gcc@$spack_gcc_version; \
#spack compiler find; \
#spack unload; \
#spack install -j 30 flux-sched%gcc@$spack_gcc_version; \
#spack install -j 30 flux-sched%gcc@$gcc_version ^openmpi%gcc@gcc_version; \

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
# spack install flux-core%gcc@12.2.0 ^slurm+pmix
# compiles most of Flux.  One downside is it takes an
# extra ~22 minutes (on 8 CPU) to compile the compiler itself.
# Also, hwloc does not compile because missing OpenMPI. So,
# also need to:
# spack install openmpi%gcc@12.2.0+pmi ^slurm+pmix
# (when then installs hwloc as part of openmpi!)
# Note need the +pmi to work with srun
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

# Try build with all code?
# causes follow on failures of libarchive, flux-core, flux-shed
echo 'source ~/.bashrc; \
spack install -j 30 gcc@12.2.0; \
spack load gcc@12.2.0; \
spack compiler find; \
spack unload; \
spack install -j 30 openmpi%gcc@12.2.0+pmi ^slurm+pmix; \
spack install -j 30 flux-sched%gcc@12.2.0 ^openmpi+pmi ^slurm+pmix;' | /bin/bash
#spack install -j 30 flux-sched cflags=="-std=c99" ^openmpi+pmi ^slurm+pmix;' | /bin/bash

#spack install -j 30 intel-oneapi-compilers; \
#spack load intel-oneapi-compilers; \
#spack compiler find; \
#spack unload; \
#spack install -j 30 intel-oneapi-mpi%intel; \
#spack install -j 30 flux-sched%intel ^intel-oneapi-mpi' | /bin/bash #scl enable devtoolset-7 bash

# Setup Spack env
#source ~/.bashrc
#spack install -j 30 gcc
#spack load gcc
#spack compiler find
#spack install -j 30 openmpi
#spack install -j 30 flux-sched

#==============================
#echo Install Parsl in Spack Miniconda...
#==============================
source $HOME/.bashrc
spack install miniconda3
spack load miniconda3
conda install -y -c conda-forge parsl
conda install -y sqlalchemy
conda install -y sqlalchemy-utils
pip install "parsl[monitoring]"

#==============================
#echo Install local Miniconda...
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

