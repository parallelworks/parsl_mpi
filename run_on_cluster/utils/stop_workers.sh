#!/bin/bash
#=========================
# Stop the workers listed
# in the first command line
# argument to this script, e.g.
#
# stop_workers.sh 
#
#=========================

echo "Attempting to power down ${1}"
sudo scontrol update nodename=${1} state=power_down

