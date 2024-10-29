#! /bin/bash
#===========================
# Install Intel OneAPI directly
# on the system instead of with
# Spack. This is because we need
# v2024.2.0 due to seg fault errors
# in the previous versions.
#
# https://community.intel.com/t5/Intel-Fortran-Compiler/Internal-compiler-error-segmentation-violation-signal-raised/td-p/1590217
#
# and the version of Spack currently
# supported by spackstack 1.8.0 is limited
# to Intel OneAPI v2024.1.0.
#
# This script is based on the instructions at:
# https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2023-0/yum-dnf-zypper.html
#===========================

# Set up a repo connect file
tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

# Allow yum to use this file
sudo mv /tmp/oneAPI.repo /etc/yum.repos.d

# I think there's something going on with the linking
# or paths in intel-hpckit-2024.2.1. When spack adds the
# compiler in this version, there are always duplicates.

# Keep a copy of the .rpms on this image in case we need to reinstall
sudo mkdir -p /opt/rpms
sudo mkdir -p /tmp/rpms
sudo yum install -y --downloadonly --downloaddir=/tmp/rpms intel-hpckit
sudo rsync -av /tmp/rpms/ /opt/rpms

# Install - everything goes to /opt/intel/oneapi/
# and it is NOT automatically included in the path.
# To put it on your path, source /opt/intel/oneapi/setvars.sh
sudo yum -y install intel-hpckit

# In mid 2024, the above installs only mpiifx. mpiifort is
# automatically replaced with mpifx. If you really do want
# ifort as the backend compiler with Intel MPI (i.e. true
# mpiifort) then you need to install this extra package:
#
# This seems to install for 2024.2.1, not 2025.0
# This installs the newest version by default with
# the hpckit (2021.14) - my successful build had
# used 2021.14 with the default source /opt/intel/oneapi/setvars.sh
# but I had run yum install intel-oneapi-mpi-devel-2021.13 beforehand
# - double check without this.
#sudo yum install -y --downloadonly --downloaddir=/tmp/rpms intel-oneapi-mpi-devel-2021.13
#sudo rsync -av /tmp/rpms/ /opt/rpms
#sudo yum install -y intel-oneapi-mpi-devel

echo You can now use Intel OneAPI with /opt/intel/oneapi/setvars.sh --config=/full/path/to/oneapi.config

