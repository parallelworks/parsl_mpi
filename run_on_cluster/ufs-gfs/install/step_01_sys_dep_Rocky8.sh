#! /bin/bash
#=====================================
# System dependencies for building UFS
# on Rocky8 images. This script is based
# on the recipe provided at:
#https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#prerequisites-red-hat-centos-8-one-off
#=====================================

echo Starting step 01 install system dependencies...

#===========================================
# General update
# Is this required? May not work with cloud clusters since image is tuned.
# Comment out for now since it takes a long time (250+ packages get pulled
# and installed).
#===========================================
#sudo yum -y update

#===========================================
# Update certificates if the image is really old
#===========================================
sudo yum update -y ca-certificates

#===========================================
# Core compiler tools that are required
# You can choose other versions of gcc
# by changing out gcc_ver. I've tested
# 9, 10, and 11. Once installed, must:
#
# source /opt/rh/gcc-toolset-${gcc_ver}/enable
#
# for automated access OR for an interactive session:
#
# scl enable gcc-toolset-${gcc_ver} bash
#
#==========================================
gcc_ver=11
sudo yum -y install gcc-toolset-${gcc_ver}-gcc-c++
sudo yum -y install gcc-toolset-${gcc_ver}-gcc-gfortran
sudo yum -y install gcc-toolset-${gcc_ver}-gdb

# Do NOT blanket install the whole toolset since
# there may be issues with cmake (see below).
#sudo yum install gcc-toolset-11

#===========================================
# Other dependencies (may already be present on the image)
#===========================================
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
sudo yum -y install perl-IPC-Cmd
sudo yum -y install texlive
# Do not install qt@5 for now

# Autopoint needed for autoconf, spack-stack 1.8.0
sudo yum -y install gettext-devel

# Note - only needed for running JCSDA's
# JEDI-Skylab system (using R2D2 localhost)
# Currently mysql-server is incompatible with 
# mariadb installation on PW Rocky8 images
# (The two have near duplicate functionality?)
# You can force install, which will remove 
# mariadb. Comment out for now.
#sudo yum -y install --allowerasing mysql-server

# Set a specific version of Python
sudo yum -y install python39-devel
sudo alternatives --set python3 /usr/bin/python3.9

# Install boto3 into the running version of Python
python3 -m pip install boto3

#=====================WARNING=======================
# The following install steps ASSUME that you are running
# in the gcc-toolset-11 enabled bash shell. See the 
# scl or source commands above.
#====================================================

echo Done installing system dependencies

