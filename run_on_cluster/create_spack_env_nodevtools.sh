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
#echo Install newer version of gcc...
#==============================

#sudo yum install -y centos-release-scl
#sudo yum install -y devtoolset-7

#==============================
echo Explicit install of OpenMPI outside of Spack
#==============================

gcc_version=$(gcc --version | awk 'NR==1{print $3}')
echo "===> Will build OpenMPI with gcc v$gcc_version"

echo "===> Set up OpenMPI build environment variables"

# OpenMPI needs to be installed in a shared directory
export OMPI_DIR=${HOME}/ompi
mkdir -p $OMPI_DIR/bin
mkdir -p $OMPI_DIR/lib

# Update OpenMPI version as needed
export OMPI_MAJOR_VERSION=4.1
export OMPI_MINOR_VERSION=.5
export OMPI_VERSION=${OMPI_MAJOR_VERSION}${OMPI_MINOR_VERSION}
export OMPI_URL_PREFIX="https://download.open-mpi.org/release/open-mpi"
export OMPI_URL="$OMPI_URL_PREFIX/v$OMPI_MAJOR_VERSION/openmpi-$OMPI_VERSION.tar.gz"
export PATH=$OMPI_DIR/bin:$PATH
export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
export MANPATH=$OMPI_DIR/share/man:$MANPATH
# For SLURM-OpenMPI integration (i.e. launch via srun)
export OMPI_SLURM_PMI_INCLUDE=/usr/include/slurm
export OMPI_SLURM_PMI_LIBDIR=/usr/lib64
export C_INCLUDE_PATH=/usr/include/slurm

echo "===> Making /tmp/ompi work dir"
# Do not delete existing temporary OMPI dir to speed
# up development testing of downstream Spack actions
#rm -rf /tmp/ompi
mkdir -p /tmp/ompi

echo "===> Downloading OpenMPI v$OMPI_VERSION"
cd /tmp/ompi && wget -O openmpi-$OMPI_VERSION.tar.gz $OMPI_URL && tar -xzf openmpi-$OMPI_VERSION.tar.gz

echo "===> Compile and install OMPI"
# Allow for up to 30 concurrent compile jobs with -j
cd /tmp/ompi/openmpi-$OMPI_VERSION && ./configure --prefix=$OMPI_DIR --with-flux-pmi --with-pmi=$OMPI_SLURM_PMI_INCLUDE --with-pmi-libdir=$OMPI_SLURM_PMI_LIBDIR && make install -j 30

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

#git clone -b v0.19.2 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

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
#echo "  openmpi:" >> $spack_packages
#echo "    externals:" >> $spack_packages
#echo "    - spec: openmpi@$OMPI_VERSION%gcc@$gcc_version" >> $spack_packages
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

# mbedtls requires gcc -std=c99.
# Try build with all code?
# causes follow on failures of libarchive, flux-core, flux-shed
echo 'source ~/.bashrc; \
spack compiler find; \
spack unload; \
spack install mbedtls@2.28.0 cflags=="-std=c99" \
spack install -j 30 flux-sched ^openmpi ^slurm; \
spack install -j 30 intel-oneapi-compilers; \
spack load intel-oneapi-compilers; \
spack compiler find; \
spack unload; \
spack install -j 30 intel-oneapi-mpi%intel; \
spack install -j 30 flux-sched%intel ^intel-oneapi-mpi' | /bin/bash #scl enable devtoolset-7 bash

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
#source $HOME/.bashrc
#spack install miniconda3
#spack load miniconda3
#conda install -y -c conda-forge parsl
#conda install -y sqlalchemy
#conda install -y sqlalchemy-utils
#pip install "parsl[monitoring]"

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

