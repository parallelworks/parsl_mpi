# Installation of UFS on cloud clusters

Weather models are perfect examples of complex software 
stacks due to the many dependencies that underpin them.
Here, we step through the process of setting up the:
1. system level dependencies (OS-level package installs),
2. package manager depenendencies (i.e. Spack and Conda), and
3. final application build

## A) System-level dependencies

### Module setup

PW cloud cluster images are set up for `module load` to pull from `/apps`. If there
is no `/apps` attached flexible storage, then `module` commands will not work. Use
`step_00_lmod_reset.sh` to delete this initial `module` configuration so you can use
`module use /path/to/modulefiles` and `module load <package>` later with `spack-stack`.

### Rocky8

See `step_01_sys_dep_Rocky8.sh` for system install based on these 
[instructions](https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#prerequisites-red-hat-centos-8-one-off). 
Deviations from these instructions include:
1. not running `sudo yum -y update` since cloud images' packages 
   are carefully tuned and it will take long time.
2. Updating ca-certifiates because using a static image.

### Centos7

Coming soon.

## B) Package manager dependencies (spack-stack)

### Building spack-stack

Run `step_02_spack_stack_intel.sh` to install and setup `spack-stack` as
well as build the dependencies for the `ufs-weather-model` as defined by
the template with the same name in `spack-stack/configs/templates`.

If you have a Spack buildcache in an AWS bucket, you can copy and paste the
credentials into your running session and those environment variables will
be used by `step_02_spack_stack_intel.sh` to connect to the cache and
speed up the build with precompiled binaries. If the credentials are not
present, it will simply build from scratch (expect a few hours).

### Testing MPI

#### Intel OneAPI compilers with Intel MPI

Once spack-stack is installed and started (i.e. the environment is setup),
you can use `mpicc` to compile MPI enabled code. You can check that it is
indeed using Intel MPI with `which mpicc` whose result, when using spack-stack,
will list a long path whose name will include `intel-oneapi-mpi`.

For a simple `hello-world` type MPI program (i.e. ./mpitest.c at the
top level of this repo), you can simply invoke:
```
# Build:
mpicc ~/parsl_utils/mpitest.c

# Set fabric env variable (may be different for each CSP)
# or whether using high-speed networking or not.
export I_MPI_FABRICS=shm:ofi

# Run with 4 CPU/processes on 2 nodes on the partition named "small":
sbatch --output=tmp.std.out --nodes=2 -p small --wrap "mpiexec.hydra -np 4 ~/a.out"
```
The log file `tmp.std.out` should have similar output as:
```
Hello world from processor sfgary-cloud2-00180-2-0002, rank 1 out of 4 processors
Hello world from processor sfgary-cloud2-00180-2-0002, rank 3 out of 4 processors
Hello world from processor sfgary-cloud2-00180-2-0001, rank 2 out of 4 processors
Hello world from processor sfgary-cloud2-00180-2-0001, rank 0 out of 4 processors
```
Note in particular the total number of processors, that there are exactly two
processors on each node, two different nodes (0002 and 0001) are used, and each
processor has a unique rank (1, 2, 3, and 4).

Some potential indicators of incorrect configuration are:
+ same rank of zero for all processors
+ same node used, in particular the mgmt- (head) node instead of worker nodes

### GCC, OpenMPI and MPICH inside Spack

Coming soon

## C) Archiving

Run `step_03_push_to_buildcache.sh` to save the binary executables to the buildcache
so they can be used later. This step is optional.

## D) Final build

The build has two parts: 1) setting up the build environment (i.e. access to the libraries
and executables in `spack-stack`) and 2) actually compiling the core components of UFS.
+ `source step_04_ufs_build_env_intel.sh` will set up the build environment (there's a lot of unused,
   commented out code in this script incase I need to revert to situations where 
   `module load stack-*` does not work - this step is really only 4 commands when all is
   working as it should). Note that I `source` this script to set the environment variables
   in my running session instead of just running the script.
+ `step_05_build.sh` clones the `ufs-weather-model` repo, sets UFS application-specific
   environment variable flags, and kicks off the build process.

## E) Download input data

`step_06_get_input_data.sh` automates the process of downloading the input data.

## F) Launch the model and monitor

## G) View the results


