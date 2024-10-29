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

It seems that `source /etc/profile.d/modules.sh` works better than `source ~/.bashrc`
for after `step_00_lmod_reset.sh` is run. Perhaps autosetup access to modules was 
changed from the system bashrc in `/etc` in the newest image?

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

On a PW cluster, you can autheticate to the PW CLI with
```
pw auth token
```
and then use the PW CLI to list buckets and get their
credentials with:
```
# Which buckets do I have access to?
pw buckets list

# Load short term bucket credentials as env. variables
eval `pw buckets get-token <spack-buildcache-bucket-name>
```

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

I don't know how to get PMI to talk with Intel MPI, so that's why I used the
`sbatch` approach to launching the test, above. Trying with a simple 
`srun --nodes 2 -N 4 ...` (implicit PMI) results in lots of errors.

### OneAPI versus "classic" Intel

Intel is going to transition away from its classic compiler names (e.g. `icc`) and move to 
the OneAPI compilers (e.g. `icpx`). This is particularly strong starting with 2024 versions
and spackstack 1.8 supports the OneAPI approach. Within spackstack, however, you need to
specify `oneapi` instead of `intel` throughout.

Unfortunately, the OneAPI compilers seg fault when building `fms` for versions 2024.1 and 
lower. So, it only works for 2024.2+. However, spackstack 1.8's internal version of Spack
does not include OneAPI 2024.2, so in order to use 2024.2 (right now) I had to install
it direclty as a system install instead of installing it through Spack. This adds complexity
to the process since it (and compatible Intel MPI) needs to be installed directly on each node
instead of through Spack because the install location is not shared among nodes in `/opt/intel`.
Hopefully, this will be resolved in a future version of spackstack and we can resume with
Spack installed Intel compilers. But for now, the `*_oneapi*` designation applies to build
scripts that depend on Intel OneAPI as an **external** dependency to Spack, not an internal.

### GCC, OpenMPI and MPICH inside Spack

Coming soon

## C) Archiving

Run `step_03_push_to_buildcache.sh` to save the binary executables to the buildcache
so they can be used later. This step is optional.

## D) Final build

The build has two parts: 1) setting up the build environment (i.e. access to the libraries
and executables in `spack-stack`) and 2) actually compiling the core components of UFS.
+ `source step_04_ufs_build_env_intel.sh` will set up the build environment (there's a lot of unused,
   commented out code in this script in case I need to revert to situations where 
   `module load stack-*` does not work - this step is really only 4 commands when all is
   working as it should). Note that I `source` this script to set the environment variables
   in my running session instead of just running the script.
+ `step_05_build.sh` clones the `ufs-weather-model` repo, sets UFS application-specific
   environment variable flags, and kicks off the build process. Depending on the exact
   branch or version of the code, the build process for this default case may or may not 
   complete. This is why using the unit testing framework (Steps E-G below) may be more useful.

## E) Select unit test

+ control_c48 - very small (single node?)
+ control_c192 - medium size, can test scaling to multiple nodes, 
                 but `rt.conf` excludes it from `noaacloud`. Test
                 data is 5.1GB.
+ control_c384 - larger scale, test data is 19.9GB.

## F) Download input data

`step_06_get_input_data.sh` automates the process of downloading the input data.

## G) Launch the model and monitor

To launch a regression test, we use the `ufs-weather-model/tests/rt.sh` framework. To launch
a single test, try the following:
1. Set the date of the baseline to compare to in `ufs-weather-model/tests/bl_date.conf`. 
   I set `export BL_DATE=20240426` or `20240821` since it is present in the cloud data 
   bucket. There are more recent dates in the repo but they are only available on-prem.
   *IT IS NOT SUFFICIENT TO EXPORT THIS IN YOUR ENV - IT MUST BE IN `bl_date.conf`.*
2. Due to the `$PW_CSP` environment variable, `ufs-weather-model/tests/detect_machine.sh`
   detects whether the cluster is on GCP, AWS, or Azure and assigns it a `noaacloud` `MACHINE_ID`.
3. Adjust four key paths in `rt.sh` under the `noaacloud` `MACHINE_ID` `case` switch. In particular,
   + comment out `export PATH="/contrib/EPIC/bin:${PATH}"` and 
   + comment out `module use /apps/modules/modulefiles` 
   because the binaries/libraries are already loaded in `source step_04_...`. Then, adjust:
   + `dprefix="${HOME}"  # Was /lustre/`
   + `DISKNM="${HOME}/RT" # Was "/contrib/ufs-weather-model/RT"`
   If you don't have `/lustre` or `/contrib` configured. The `DISKNM` parameter is the root
   path for accessing the downloaded regression test input files from `step_06_...`.
4. Also in the `noaacloud` switch, adjust the `PARTITION` if a custom partition name is needed.
   In general, the compile and test jobs will launch on worker nodes. Internally, `sbatch` 
   "job cards" are created in `./stmp2/` and the number of `tasks-per-node` is set based on
   the larger, assumed instance types on each CSP as determined by `$PW_CSP`:
   + `google` -> 30 (for c2-standard-60 with hyperthreading turned off)
   + `azure`  -> 44 (for HC44rs)
   + `aws`    -> 36 or 96 (probably for c5n.18xlarge with hyperthreading turned off, or hpc6a) 
5. `./rt.sh -n "control_c48 intel" -a myaccount`
   + Logs are sent to `ufs-weather-model/tests/logs/log_<MACHINE_ID>`
   + Needed to adjust the number of CPU I can use for compile or running jobs. This value is
     set in `ufs-weather-model/tests/default_vars.sh` and changes based on `PW_CSP` where it
     is assumed that cluster worker nodes have a specific size for each CSP.
   + `tests/compile.sh` is trying to load modules and failing - don't need this since I've preloaded my spack-stack. WORKING HERE


   + As of summer 2024, ufs-weather-model is in the process of going from sp 2.3.3 to ip 5.0.0: https://github.com/JCSDA/spack-stack/discussions/1206. In order to compile directly, need to change out reference to sp in the CMakeLists.txt in `ufs-weather-model`, `FV3`, `FV3/ccpp/physics` to references to ip and compilation seems to run OK. It should be a one-to-one replacement...
   + With OneAPI, need to add an & to end of: https://github.com/earth-system-radiation/rte-rrtmgp/blob/74a0e098b2163425e4b5466c2dfcf8ae26d560a5/rrtmgp/mo_gas_optics_rrtmgp.F90#L1770 This seems to be a valid syntax error based on the structure of other usage of this OMP command.

## H) View the results


