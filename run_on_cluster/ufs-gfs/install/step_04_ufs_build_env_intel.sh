#!/bin/bash
#============================================
# Set up the build environment for UFS.
# SOURCE this script, don't just run it
# because you want the settings here to
# persist in your build environment. If
# you just run it, these settings are set
# in a child process but do not propagate
# back to your current process.
#============================================
echo Get access to updated gcc toolset...
# The Intel compiler uses some GCC libraries
# in the background, so it is best to use the
# same GCC as when the spack-stack was built.
source /opt/rh/gcc-toolset-11/enable

echo Get access to Intel compiler meta-module...
# Instructions at: https://spack-stack.readthedocs.io/en/latest/UsingSpackEnvironments.html#usingspackenvironments
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles/Core
module load stack-intel

# These two don't work unless you have MPI listed
# in spack-stack/envs/<env>/site/packages.yaml.
module load stack-intel-oneapi-mpi
module load stack-python

# This won't work as is unless the module load spack-*
# lines above work.
module load ufs-weather-model-env

#============================================
# You can generally ignore everything between
# here: START IGNORE and END IGNORE, below,
# unless you're having configuration
# and/or module load errors from the above.
#============================================

echo "=============================="
echo Test Intel compiler:
`$CC -v`
echo "=============================="
# BUT: module load stack-python and module load stack-intel-oneapi-mpi
# do not work as suggested in the docs.

echo Get access to Intel MPI...
# Need to get access to `icc`, `mpiicc`, etc.
# Those same executables should be defined in
# the paths set by the meta-modules, above,
# and since they work, I can comment out all
# this.
#source /home/sfgary/spack/spack-stack/setup.sh
#spack load intel-oneapi-compilers
#spack load intel-oneapi-mpi
echo "=============================="
#echo Test Intel icc access:
#icc --version
#echo Test Intel mpiic access:
#mpiicc --version
echo Test Intel mpiexec access:
mpiexec --version
echo "=============================="

echo Load ufs-weather-model-env...
# I use this if the module load stack-* commands above
# don't work because it uses the default Spack-generated
# original module files, not the spack-stack meta module.
# There is probably overlap/duplication here.
# Since module load stack-* commands above work, comment
# this out.
#module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles
#module load intel-oneapi-mpi/2021.10.0/intel/2021.3.0/ufs-weather-model-env/1.0.0

#=================================
# END IGNORE
#=================================

echo Set env vars for compilers...
#Instructions at: https://ufs-weather-model.readthedocs.io/en/develop/BuildingAndRunning.html#building-the-weather-model
export CMAKE_C_COMPILER=mpicc
export CMAKE_CXX_COMPILER=mpicxx
export CMAKE_Fortran_COMPILER=mpiifort

# If there are convoluted paths...
#export CMAKE_C_COMPILER=`which mpiicc`
#export CMAKE_CXX_COMPILER=`which mpiicpc`
#export CMAKE_Fortran_COMPILER=`which mpiifort`

export CMAKE_Platform=linux.intel

