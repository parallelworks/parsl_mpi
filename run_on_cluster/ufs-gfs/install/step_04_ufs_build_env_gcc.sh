# Use and load modules: https://spack-stack.readthedocs.io/en/latest/UsingSpackEnvironments.html#usingspackenvironments
module use /home/sfgary/spack/spack-stack/envs/ufs-weather-model.mylinux/install/modulefiles/Core
module load stack-gcc
module load stack-openmpi
module load stack-python
# Set build env: https://ufs-weather-model.readthedocs.io/en/develop/BuildingAndRunning.html
export CMAKE_C_COMPILER=`which mpicc`
export CMAKE_CXX_COMPILER=`which mpicxx`
export CMAKE_Fortran_COMPILER=`which mpifort`
export CMAKE_Platform=linux.gnu
# Choose which UFS app/config to build
export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"

