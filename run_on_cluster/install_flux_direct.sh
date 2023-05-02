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
sudo ./install-deps-rpm.sh

# Missing dependencies?
# flux-core
sudo yum install -y ncurses-devel
sudo yum install -y libsodium-devel
# flux-sched (after flux-core is compiled)
sudo yum install -y yaml-cpp
sudo yum install -y yaml-cpp-devel
sudo yum install -y libedit-devel

# Optional dependencies that are used 
# in make check or building docs?
sudo yum install -y libfaketime
sudo yum install -y python-sphinx

# Flux is installed to flux_prefix
flux_prefix=$HOME/local
mkdir -p flux_prefix

# Static linking to try putting all
# dependencies in the the same place!
#export LDFLAGS=" -static "

# Got this warning:
#sfgary/bin:/home/sfgary/local/bin:/sbin" ldconfig -n /home/sfgary/local/lib/flux/modules
#----------------------------------------------------------------------
#Libraries have been installed in:
#   /home/sfgary/local/lib/flux/modules
#
#If you ever happen to want to link against installed libraries
#in a given directory, LIBDIR, you must either use libtool, and
#specify the full pathname of the library, or use the `-LLIBDIR'
#flag during linking and do at least one of the following:
#   - add LIBDIR to the `LD_LIBRARY_PATH' environment variable
#     during execution
#   - add LIBDIR to the `LD_RUN_PATH' environment variable
#     during linking
#   - use the `-Wl,-rpath -Wl,LIBDIR' linker flag
#   - have your system administrator add LIBDIR to `/etc/ld.so.conf'
#
#See any operating system documentation about shared libraries for
#more information, such as the ld(1) and ld.so(8) manual pages.
#----------------------------------------------------------------------

echo "======================================"
echo Build flux-core
echo "======================================"
# NOTE: make check step can take a while (30 mins), 
# commented out for regular node deployment
cd ~/flux-core
./autogen.sh && ./configure --prefix=$flux_prefix
make -j 8
# make check
make install

echo "======================================"
echo Build flux-sched
echo "======================================"
cd
git clone https://github.com/flux-framework/flux-sched.git
cd flux-sched
./autogen.sh && ./configure --prefix=$flux_prefix
make -j 8
#make check 
make install
