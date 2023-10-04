#!/bin/bash
#==============================
# Install gcc7 on system
#==============================
echo Install newer version of gcc...
#==============================

sudo yum install -y centos-release-scl
sudo yum install -y devtoolset-7

# Once this is complete, you can 
# use gcc7 instead of gcc4, e.g.
# echo "./step_00b__install_openmpi_no_Spack.sh" | scl enable devtoolset-7 bash

# Or just ensure that the following
# is in ~/.bashrc:
echo "source /opt/rh/devtoolset-7/enable" >> ~/.bashrc

