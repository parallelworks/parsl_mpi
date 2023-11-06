#!/bin/bash
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
# The OpenFOAM11 container currently has
# OpenMPI 4.0.3, so match that here.
export OMPI_MAJOR_VERSION=4.0
export OMPI_MINOR_VERSION=.3
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

echo "Now that OpenMPI is installed, test it with the following steps:"
echo "# Compile text code"
echo "mpicc -o mpitest.out mpitest.c"
echo "# Run test with PMI"
echo "srun -N 2 -n 4 --mpi=pmi2 mpitest.out"
echo "# Run test without PMI"
echo "mpiexec -N 2 mpitest.out"

