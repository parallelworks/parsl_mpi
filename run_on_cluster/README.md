# MPI applications for direct run on clusters

This directory contains various template/examples
for running MPI jobs with Parsl. This code, including
software install, endpoint setup, and environment
config, is a work in progress. BY "direct run" on
clusters, these examples are meant to be launched
interactively and are not yet workflow orchestrated.

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

## Notes on MPI setup

### OpenMPI

The `hello-world` and `openfoam` cases use OpenMPI. Some CSP
images do not have OpenMPI pre-installed, so for consistency,
we build it from scratch here. This also allows the user to
be explicit about building OpenMPI with PMI2/PMIx support which
appears to be particuarly important when running __containerized__
MPI applications.

The trick is to get OpenMPI to talk to the high performance
network fabrics on each CSP. Some helpful approaches to this
are running:
```
# Get list of top level options
/path/to/ompi/bin/ompi_info

# Get list of BTL options
/path/to/ompi/bin/ompi_info --param btl tcp --level 9
```
In general, it is the `mpiexec --mca btl_tcp_if_include <network>`
option that will get you to the high performance fabrics.
For each CSP (and with the appropriate supported compute node type):
+ GCE:   Use `eth0` to get to the gVNIC. You can test gVINC access with
  `sudo lshw -class network` and the `Product:` line should display gVINC.
+ AWS:   Use `` to get to the EFA
+ Azure: Use `` to get to the InfiniBand

__TEST THIS HYPOTHESIS:__ In general, you don't need to compile OpenMPI on a high-performance
capable node - smallish head nodes without access to the high performance fabrics
can build OpenMPI on each respectinve CSP and
the libraries can be stored (i.e. on images or mounted disks/filesystems) for reuse
by the bigger nodes with access to the high performance network fabrics.

### Intel OneAPI MPI

The `ufs-gfs` use case uses Intel OneAPI MPI which is
installed as part of `spack-stack`. `spack-stack` also
supported OpenMPI, but in general the performance with
Intel compilers and MPI is better than with `gcc`.

