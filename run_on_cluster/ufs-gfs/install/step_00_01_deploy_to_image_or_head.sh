#! /bin/bash
#=================================
# Wrapper for step_00_01 for
# automated image builds on CSPs.
# This script can be used to deploy
# on a head node, too.
#
# The only difference is that
# a source line is included
# in the ~/.bashrc and its
# sourced here just in case.
#==================================

current_host=`hostname`

./step_00_lmod_reset.sh 1> ./deploy.${current_host}.stdout 2> ./deploy.${current_host}.stderr
echo "source /etc/profile.d/modules.sh" >> ~/.bashrc
source /etc/profile.d/modules.sh
./step_01_sys_dep_Rocky8.sh 1>> ./deploy.${current_host}.stdout 2>> ./deploy.${current_host}.stderr
./step_01a_sys_install_oneapi.sh 1>> ./deploy.${current_host}.stdout 2>> ./deploy.${current_host}.stderr

