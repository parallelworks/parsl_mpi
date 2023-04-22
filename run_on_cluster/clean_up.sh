#!/bin/bash
#=================================
# Clean up all output files from
# a Parsl session.
#=================================

# Parsl "local" logs - logs from
# the main orchestration engine of Parsl
# (i.e. logs that are "local" to the user)
# In the case of a PW workflow running on 
# a cloud cluster, these are the logs on
# the PW platform.
rm -rf runinfo

# Parsl "remote" logs - logs from the
# compute resources that are "remote" to
# the user.  In the case of a PW workflow
# running on a cloud cluster, these are the
# logs on the cluster.
rm -rf slurm_provider

# Stdout and stderr for the Parsl Apps in the workflow
rm -f compile*.out
rm -f compile*.err

rm -f run-*.out
rm -f run-*.err

# Explicit output from the Parsl Apps (not just stdout/stderr)
rm -f hello-*.out
rm -f mpitest*
