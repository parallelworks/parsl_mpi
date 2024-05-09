echo Get access to Intel compiler meta-module...
# Instructions at: https://spack-stack.readthedocs.io/en/latest/UsingSpackEnvironments.html#usingspackenvironments
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles/Core
module load stack-intel
echo "=============================="
echo Test Intel compiler:
`$CC -v`
echo "=============================="
# BUT: module load stack-python and module load stack-intel-oneapi-mpi
# do not work as suggested in the docs.

echo Get access to Intel MPI...
# Need to get access to `icc`, `mpiicc`, etc.
# Those same executables should be defined in
# the paths set by the meta-modules, above.
source /home/sfgary/spack/spack-stack/setup.sh
spack load intel-oneapi-compilers
spack load intel-oneapi-mpi
echo "=============================="
echo Test Intel icc access:
icc --version
echo Test Intel mpiic access:
mpiicc --version
echo Test Intel mpiexec access:
mpiexec --version
echo "=============================="

echo Load ufs-weather-model-env...
# This works because it uses the default Spack-generated
# original module files, not the spack-stack meta module.
# There is probably overlap/duplication here.
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles
module load intel-oneapi-mpi/2021.10.0/intel/2021.3.0/ufs-weather-model-env/1.0.0

echo Set env vars for compilers...
#Instructions at: https://ufs-weather-model.readthedocs.io/en/develop/BuildingAndRunning.html#building-the-weather-model
export CMAKE_C_COMPILER=`which mpiicc`
export CMAKE_CXX_COMPILER=`which mpiicpc`
export CMAKE_Fortran_COMPILER=`which mpiifort`
export CMAKE_Platform=linux.intel
# Choose which UFS app/config to build
export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"

