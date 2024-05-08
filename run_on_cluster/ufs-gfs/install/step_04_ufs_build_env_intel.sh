echo Get access to Intel compiler...
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles/Core
module load stack-intel
echo "=============================="
echo Test Intel compiler:
echo $CC --version
echo "=============================="
which mpicc

echo Get access to Intel MPI...
source /home/sfgary/spack/spack-stack/setup.sh
spack load intel-oneapi-compilers
spack load intel-oneapi-mpi
echo "=============================="
echo Test Intel MPI access:
mpiicc --version
echo "=============================="

echo Load ufs-weather-model-env...
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles
module load intel-oneapi-mpi/2021.9.0/intel/2021.3.0/ufs-weather-model-env/1.0.0

echo Set env vars for compilers...
export CMAKE_C_COMPILER=`which mpiicc`
export CMAKE_CXX_COMPILER=`which mpiicpc`
export CMAKE_Fortran_COMPILER=`which mpiifort`
export CMAKE_Platform=linux.intel
# Choose which UFS app/config to build
export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"

