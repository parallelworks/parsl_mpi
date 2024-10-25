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

# Keep a copy of the .rpms on this image in case we need to reinstall
sudo mkdir -p /opt/rpms
yum install -y --downloadonly --downloaddir=/opt/rpms intel-hpckit

# Install - everything goes to /opt/intel/oneapi/
# and it is NOT automatically included in the path.
# To put it on your path, source /opt/intel/oneapi/setvars.sh
sudo yum -y install intel-hpckit

# In mid 2024, the above installs only mpiifx. mpiifort is
# automatically replaced with mpifx. If you really do want
# ifort as the backend compiler with Intel MPI (i.e. true
# mpiifort) then you need to install this extra package:
yum install -y --downloadonly --downloaddir=/opt/rpms intel-oneapi-mpi-devel
sudo yum install intel-oneapi-mpi-devel

