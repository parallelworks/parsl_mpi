#!/bin/bash
#==========================
# To run this script on a
# bunch of worker nodes:
#
# srun --nodes <number_of_workers_you_want> -p <partition> ./step_00_01_deploy_to_workers.sh
#
#==========================

current_host=`hostname`

./step_00_lmod_reset.sh 1> ./deploy.${current_host}.stdout 2> ./deploy.${current_host}.stderr
./step_01_sys_dep_Rocky8.sh 1>> ./deploy.${current_host}.stdout 2>> ./deploy.${current_host}.stderr
./step_01a_sys_install_oneapi.sh 1>> ./deploy.${current_host}.stdout 2>> ./deploy.${current_host}.stderr

