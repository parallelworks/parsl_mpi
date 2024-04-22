#!/bin/bash
#============================================
# Start an MPI enabled globus compute endpoint
#
# Setup:
# 1) First run ./create_conda_env.sh to install
# 2) Activate the installed Conda environment
# 3) Authenticate the Globus
# 4) Run this script on a cluster/endpoint.
#
# Since this is an MPI enabled endpoint, you will
# likely want to have slurm-devel and MPI libraries
# installed. See step_00a and step_00b here.
#============================================

# Name the endpoint
endpt_name=my-mpi-endpt

# Local endpoint creation
globus-compute-endpoint configure $endpt_name

# Configure the endpoint with MPI options
# based on the file here
cat my-mpi-endpt.config.yaml > ~/.globus_compute/${endpt_name}/config.yaml

# Start the endpoint
globus-compute-endpoint start $endpt_name

