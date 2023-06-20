#!/bin/bash
#===========================
# Steps for direct install of
# Flux (i.e. using sudo access
# to put it on the head node
# of a cluster).
#
# For a system install, Flux, 
# and **all dependencies**,
# are required to be installed
# on all the worker nodes too.
# On the other hand,
# Spack allows for all dependencies
# to be installed in the SPACK_HOME
# which, if on a shared disk, makes
# installation across a cluster much
# easier.
#
# This script will install all the
# system dependencies; this is the
# foundation needed before building
# and installing Flux itself.
#==========================

# Change to $HOME
cd

# Download current version of
# recommended dependency installer
# and run it.
#
# This script calls for zermq4-devel,
# which does not appear to exist, but
# no error ensues because zeromq-devel
# is installed at it is at v4.1+
git clone https://github.com/flux-framework/flux-core.git
cd flux-core/scripts/
if [ ! -f ./install-deps-rpm-y.sh ]
then
    sed 's/yum install/yum install -y/' ./install-deps-rpm.sh > ./install-deps-rpm-y.sh
fi
chmod u+x ./install-deps-rpm-y.sh
sudo ./install-deps-rpm-y.sh

# Missing dependencies necessary for builds
# flux-core
sudo yum install -y ncurses-devel
sudo yum install -y libsodium-devel
# flux-sched (after flux-core is compiled)
sudo yum install -y yaml-cpp
sudo yum install -y yaml-cpp-devel
sudo yum install -y libedit-devel
# Just plain missing until run time
# https://github.com/flux-framework/flux-core/issues/2140
sudo yum install -y rsh

# Optional dependencies that are used 
# in make check or building docs?
sudo yum install -y libfaketime
sudo yum install -y python-sphinx
