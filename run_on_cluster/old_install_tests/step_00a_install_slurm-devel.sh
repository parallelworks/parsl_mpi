#!/bin/bash
#================================
# The :Latest PW cluster images
# don't have the slurm-dev RPM
# installed by default. This is
# a temporary situation and this
# patch script will grab it and
# install.
#================================

tmpworkdir=/tmp/slurm-devel
rm -f $tmpworkdir
mkdir -p $tmpworkdir

scp $PW_USER@usercontainer:/pw/dev/pworks-vm-images/common_files/x86_64/slurm-devel-20.02.7-1.el7.x86_64.rpm $tmpworkdir/

cd $tmpworkdir
sudo yum install -y ./slurm-devel-20.02.7-1.el7.x86_64.rpm

