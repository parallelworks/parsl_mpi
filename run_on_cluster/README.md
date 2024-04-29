This directory contains various template/examples
for running MPI jobs with Parsl. This code, including
software install, endpoint setup, and environment
config, is a work in progress.

1. **hello-world** - run an MPI hello-world test case
   with Parsl started by a Globus Compute function call
   to explore end-to-end MPI-enabled Parsl/Globus Compute.
2. **ufs-gfs** - run a large-ish weather model from a call
   to a Globus Compute endpoint. This template is similar to
   #1 above, but a much more complicated launch/simulation.
3. **openfoam** - run a medium size fluid dynamics simulation
   from MPI-enabled Parsl/Globus Compute. This case is slightly
   different from the weather model in that it uses a multi-node
   __containerized__ application while the weather model is
   installed locally via system installs and Spack.

