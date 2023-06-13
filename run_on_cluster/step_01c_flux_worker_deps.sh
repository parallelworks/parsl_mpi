#!/bin/bash
#===========================
# Steps for direct install of
# Flux (i.e. using sudo access
# to put it on the head node
# of a cluster).
#
# Flux, and **all dependencies**,
# are required to be installed
# on all the worker nodes too.
# Initial attempts at static linking
# with LDFLAGS do not appear to work.
#
# Spack allows for all dependencies
# to be installed in the SPACK_HOME
# which, if on a shared disk, makes
# installation across a cluster much
# easier.
#==========================

# Change to $HOME
cd

# Assume we have already downloaded flux-core
# Install deps to just this worker.
cd flux-core/scripts/
sudo ./install-deps-rpm.sh

# Missing dependencies?
# flux-core
sudo yum install -y ncurses-devel
sudo yum install -y libsodium-devel
# flux-sched (after flux-core is compiled)
sudo yum install -y yaml-cpp
sudo yum install -y yaml-cpp-devel
sudo yum install -y libedit-devel
# Just plain missing until run time
# https://github.com/flux-framework/flux-core/issues/2140
sudo yum install rsh

# Optional dependencies that are used 
# in make check or building docs?
sudo yum install -y libfaketime
sudo yum install -y python-sphinx


