#!/bin/bash
#======================
# This script will automate
# the direct installation of 
# Darshan, Tau, and HPCToolkit
# on PW cloud clusters.
#
# Run this after step_00a
# (some images may not have slurm-devel)
# and step_00b (need to install openmpi)
#=====================

# WARNING! Under development. The lines
# below are a loose collection of notes
# about this process and may or may not run
# to completion.

# Setup
# Tau configure will attempt to find mpicc, etc.
export PATH=$PATH:/home/sfgary/ompi/bin
# Need Linux Perf Events for PAPI
sudo yum install perf
# Need autoconf and other tools for Darshan
# This brings in a bunch of packages - I wonder
# if this will help with failing PAPI tests?
# (I hadn't installed this when configuring
# PAPI - try that later.) I'm using a very 
# old OS (CentOS7) and gcc (4.8.5) for this
# so issues are entirely possible.
sudo yum group install "Development Tools"

# Note that HPCToolkit is not included here b/c
# it requires gcc 8.x or later. Installing on CentOS7
# **requires** Spack since devtools-7 only goes
# to gcc 7.x.

# Grab profiler sources
wget https://ftp.mcs.anl.gov/pub/darshan/releases/darshan-3.4.4.tar.gz
wget https://www.cs.uoregon.edu/research/tau/tau_releases/tau-2.32.tar.gz

# Tau dependencies
wget http://tau.uoregon.edu/ext.tgz
wget http://tau.uoregon.edu/pdt.tgz
wget http://icl.utk.edu/projects/papi/downloads/papi-7.0.1.tar.gz

# Unzip sources
tar -xzf darshan-3.4.4.tar.gz
tar -xzf tau-2.32.tar.gz
tar -xzf pdt.tgz
tar -xzf papi-7.0.1.tar.gz
mv ext.tgz tau-2.32
cd tau-2.32
tar -xzf ext.tgz
cd ../

# Build PDT - install prefix needs to be in shared 
mkdir -p /home/sfgary/pdt
cd pdtoolkit-3.25.1
# Note 1 dash only on prefix!
./configure -prefix=/home/sfgary/pdt
# Tau instructions say use make while PDT says use gmake
make
make install
export PATH=$PATH:/home/sfgary/pdt/x86_64/bin
cd ..

# Build PAPI - again, share install prefix
cd papi-7.0.1/src
./configure --prefix=/home/sfgary/papi --with-perf-events
make
# DOES NOT PASS ALL TESTS!!!!
make test
make install
cd ..

# Build Tau
# By bootstrapping Tau dependencies with ext.tgz, dependencies
# are installed in Tau build directory and are linked from that
# directory.  The Tau build dir probably needs to be shared
# with the rest of the cluster AND as warned in the config
# output, things will get messed up if this directory is
# moved.
cd tau-2.32
./configure -bfd=download -dwarf=download -unwind=download -iowrapper -pdt=/home/sfgary/pdt -prefix=/home/sfgary/tau -mpi -mpiinc=/home/sfgary/ompi/include -mpilib=/home/sfgary/ompi/lib -papi=/home/sfgary/papi
# Add bins to path as suggested at end of config output
export PATH=$PATH:/home/sfgary/tau/x86_64/bin
make install
cd ..

# Testing with salloc and mpirun based on
# https://www.open-mpi.org/faq/?category=slurm
echo Tau should be installed now.
echo Please test it with:
# Compile
echo "mpicc mpitest.c"
# Must qualify the full path of executable for tau_exec
# mpirun -n 4 causes tau_exec to crash, and -np 4 hangs,
# but works without -n.
echo "salloc -N 2 -n 4 -p small mpirun tau_exec -io -memory /home/sfgary/parsl_mpi/a.out"

# Build Darshan
# https://www.mcs.anl.gov/research/projects/darshan/docs/darshan-runtime.html#_conventional_installation
mkdir -p /home/sfgary/darshan
mkdir -p /home/sfgary/darshan-logs
cd darshan-3.4.4
./prepare.sh
cd darshan-runtime
./configure --prefix=/home/sfgary/darshan --with-log-path=/darshan-logs --with-jobid-env=PBS_JOBID CC=mpicc
make
make install

# Test Darshan
# darshan-gen-cc.pl has an error for (old?) mpicc version printing.
# I manually changed it to: `$input_file -v 2>&1 | tail -1`
# and then created a mpicc.darshan instrumentation wrapper.
# Compilation run fine, but I'm getting "WARNING OpenMPI accepted at TCP
# connection..."
