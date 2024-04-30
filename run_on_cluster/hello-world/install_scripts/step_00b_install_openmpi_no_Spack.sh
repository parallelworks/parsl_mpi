#!/bin/bash
#==============================
echo Explicit install of OpenMPI outside of Spack
#==============================

# Need to install pmi.h headers
sudo yum install -y pmix-devel

gcc_version=$(gcc --version | awk 'NR==1{print $3}')
echo "===> Will build OpenMPI with gcc v$gcc_version"

echo "===> Set up OpenMPI build environment variables"

# OpenMPI needs to be installed in a shared directory
export OMPI_DIR=${HOME}/ompi
mkdir -p $OMPI_DIR/bin
mkdir -p $OMPI_DIR/lib

# Update OpenMPI version as needed
# v5.0+ requires PMIx.
# OpenMPI 4.1.6
#export OMPI_MAJOR_VERSION=4.1
#export OMPI_MINOR_VERSION=.6
# OpenMPI 5.0.1 (Recommended by spack-stack)
export OMPI_MAJOR_VERSION=5.0
export OMPI_MINOR_VERSION=.1
export OMPI_VERSION=${OMPI_MAJOR_VERSION}${OMPI_MINOR_VERSION}
export OMPI_URL_PREFIX="https://download.open-mpi.org/release/open-mpi"
export OMPI_URL="$OMPI_URL_PREFIX/v$OMPI_MAJOR_VERSION/openmpi-$OMPI_VERSION.tar.gz"
export PATH=$OMPI_DIR/bin:$PATH
export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
export MANPATH=$OMPI_DIR/share/man:$MANPATH
# For SLURM-OpenMPI integration (i.e. launch via srun).
# Requires slurm-devel for pmi<1|2|x>.h header files.
# If you do not have access to these, you can still use
# mpiexec with sbatch, but you won't be able to launch
# MPI jobs directly with srun (see examples below).
# To disable these config options, set with_pmi=false.
# Also set to false if using OpenMPI v5+!
with_pmi=false
if [ "$with_pmi" == "true" ]; then
    echo "======> Setting OMPI_SLURM_PMI env vars..."
    # Use this if you get pmi.h from slurm-devel
    #export OMPI_SLURM_PMI_INCLUDE=/usr/include/slurm
    # Use this if you get pmi.h from pmix-devel
    export OMPI_SLURM_PMI_INCLUDE=/usr/include
    export OMPI_SLURM_PMI_LIBDIR=/usr/lib64
fi
export C_INCLUDE_PATH=/usr/include/slurm

echo "===> Making /tmp/ompi work dir"
# Do not delete existing temporary OMPI dir to speed
# up development testing of downstream Spack actions
#rm -rf /tmp/ompi
mkdir -p /tmp/ompi

echo "===> Downloading OpenMPI v$OMPI_VERSION"
cd /tmp/ompi && wget -O openmpi-$OMPI_VERSION.tar.gz $OMPI_URL && tar -xzf openmpi-$OMPI_VERSION.tar.gz

echo "===> Configure OMPI"
# Allow for up to 30 concurrent compile jobs with -j
cd /tmp/ompi/openmpi-$OMPI_VERSION

if [ "$with_pmi" == "true" ]; then
    echo "======> with PMI"
    ./configure --prefix=$OMPI_DIR --with-flux-pmi --with-pmi=$OMPI_SLURM_PMI_INCLUDE --with-pmi-libdir=$OMPI_SLURM_PMI_LIBDIR
fi

if [ "$with_pmi" == "false" ]; then
    echo "======> without PMI but with PMIX"
    ./configure --with-pmix --prefix=$OMPI_DIR
fi

echo "===> Compile and install OMPI"
make install -j 30

echo "Now that OpenMPI is installed, test it with the following steps:"
echo " "
echo "# Compile test code"
echo "${OMPI_DIR}/bin/mpicc -o mpitest.out mpitest.c"
echo " "
echo "# Run test with PMI. You may not need the --mpi=pmi2 flag."
echo "srun -N 2 -n 4 --mpi=pmi2 mpitest.out"
echo " "
echo "# Run test without PMI. mpiexec/mpirun are invoked within sbatch scripts!"
echo "# Note that here, the mpiexec -N option specifies the number of tasks per"
echo "# node, not the total number of tasks, which is what is in srun -n."
echo "sbatch --output=tmp.std.out --exclusive --nodes=2 --wrap \"${OMPI_DIR}/bin/mpiexec -N 2 a.out\""
