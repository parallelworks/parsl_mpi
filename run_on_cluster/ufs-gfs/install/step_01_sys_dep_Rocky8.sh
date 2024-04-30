#! /bin/bash
#=====================================
# System dependencies for building UFS
# on Rocky8 images. This script is based
# on the recipe provided at:
#https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#prerequisites-red-hat-centos-8-one-off
#=====================================

# Is this required? May not work with cloud clusters since image is set.
# Comment out for now since it takes a long time (250+ packages get pulled
# and installed).
#sudo yum -y update

# Core compiler tools that are required
sudo yum -y install gcc-toolset-11-gcc-c++
sudo yum -y install gcc-toolset-11-gcc-gfortran
sudo yum -y install gcc-toolset-11-gdb

# Do NOT blanket install the whole toolset since
# there may be issues with cmake (see below).
#sudo yum install gcc-toolset-11

# Other dependencies (may already be present on the image)
sudo yum -y install m4
sudo yum -y install wget
# Do not install cmake (it's 3.20.2, which doesn't work with eckit)
sudo yum -y install git
sudo yum -y install git-lfs
sudo yum -y install bash-completion
sudo yum -y install bzip2 bzip2-devel
sudo yum -y install unzip
sudo yum -y install patch
sudo yum -y install automake
sudo yum -y install xorg-x11-xauth
sudo yum -y install xterm
sudo yum -y install texlive
# Do not install qt@5 for now

# Note - only needed for running JCSDA's
# JEDI-Skylab system (using R2D2 localhost)
sudo yum -y install mysql-server

# Set a specific version of Python
sudo yum -y install python39-devel
sudo alternatives --set python3 /usr/bin/python3.9

# Install boto3 into the running version of Python
python3 -m pip install boto3

# To activate these tools (i.e. gcc v11.2.1) run
# the following as a regular user:
# scl enable gcc-toolset-11 bash
#=====================WARNING=======================
# The following steps ASSUME that you are running
# in the gcc-toolset-11 enabled bash shell.
#====================================================
