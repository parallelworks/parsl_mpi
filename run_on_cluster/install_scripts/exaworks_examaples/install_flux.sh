#!/bin/env bash

# These can be customized to suit individual needs
DEFAULT_GCC_VERSION=$(/usr/bin/gcc --version | head -1 | sed -e 's/([^()]*)//g' | awk '{print $2}')  # Version of system default gcc
DEFAULT_COMPILER="gcc@${DEFAULT_GCC_VERSION}"  # Default system compiler used to build newer gcc

SPACK_ENV_NAME="flux"            # Name of spack environment to create
SPACK_ENV_COMPILER="gcc@11.2.0"  # Compiler to use to build the spack environment
TARGET_ARCH_OPT="target=x86_64"  # Compiler architecture build target

################################################################################
# help                                                                         #
################################################################################
help()
{
   # Display help
   echo "Installs flux into flux Spack environment"
   echo
   echo "Usage: install_flux.sh"
   echo
}

# Get the location of Spack so we can update permissions
if [[ $(which spack 2>/dev/null) ]]; then
  SPACK_DIR=$(dirname $(dirname $(which spack)))
else
  echo "Cannot find Spack."
  echo
  echo "Please install Spack and/or source Spack's environment setup script: .../spack/share/setup-env.sh"
  echo
  exit 1
fi

set -eu

# Configure spack
spack config add concretizer:unify:true
spack config add concretizer:reuse:true
spack config add config:db_lock_timeout:300
spack config add config:install_tree:padded_length:128

# Load the base compiler (this assumes ./install_base.sh has already been run)
spack compiler add $(spack location -i ${SPACK_ENV_COMPILER}%${SPACK_ENV_COMPILER})

# Configure spack environment
spack env create ${SPACK_ENV_NAME} || true
spack env activate ${SPACK_ENV_NAME}

# Install $COMPILER in Spack environment
spack add ${SPACK_ENV_COMPILER} %${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack install

# Install python tools
spack add python@3.9%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-pytest%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-pylint%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-flake8%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-mypy%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-black%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add py-ply%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack add miniconda3%${SPACK_ENV_COMPILER} ${TARGET_ARCH_OPT}
spack install

# Install flux components
spack add flux-core@0.49.0%${SPACK_ENV_COMPILER} ^python@3.9 ${TARGET_ARCH_OPT}
spack add flux-sched@0.27.0%${SPACK_ENV_COMPILER} ^python@3.9 ${TARGET_ARCH_OPT}
spack install --no-checksum

# Install parsl components
#conda install -y -c conda-forge parsl

# Patch Dill Python package
#pip install 'dill @ git+https://github.com/uqfoundation/dill'

exit 0
