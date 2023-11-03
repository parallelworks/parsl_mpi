The scripts here are for running a simple Parsl workflow that launches 
an MPI hello world that queries all CPUs. There are two different Parsl scripts:
1. `slurmprovider.py` - a "out of the box" usage of MPI with Parsl's `HighThroughputExecutor` and `SlurmProvider`.
2. `slurmprovier_static_blocks.py` - a workaround/proof-of-concept to address a limitation discovered while working with `slurmprovider.py`.
3. `FluxExec_SlurmProv.py` - Use Parsl's `FluxExecutor` with the `SlurmProvider`.

The scripts here can run directly on a cluster instead of being orchestrated 
by a workflow launched from the Parallel Works platform. The goal is to isolate 
the MPI part from  the other features that are handled by 
[parsl_utils](https://github.com/parallelworks/parsl_utils). In particular,
`parsl_utils` provides support for:
1. Data transfer to remote resources
2. Multihost execution (multi cluster)
3. Monitoring
4. Python dependencies installation
5. SSH tunnels

Here, we bypass the `parsl_utils` infrastructure to simply run Parsl on 
a cluster to test Parsl configurations and examine Parsl's MPI management capabilities.

## Running with only Parsl (and without Flux)

Flux adds a lot of support for MPI jobs.  To view a Parsl-launching-MPI workflow
as a baseline for comparison with Parsl+Flux, run the scripts without Flux.

To run this test, there is a setup step that is run once followed by the
test itself that can be rerun many times.
1. Run `install_scripts/create_conda_env.sh` to create a Conda environment if you don't already have one with Parsl. The location of this Conda env is preset to `$HOME/pw/miniconda3` and its name is `parsl-mpi`. This can be changed in the script.
2. The Parsl configuration, MPI code, and test workflow are all encapsulated in `slurmprovider.py` and can be run as:
```bash
source $HOME/pw/miniconda3/etc/profile.d/conda.sh
conda activate parsl-mpi
python slurmprovider.py
```
3. There is also a `clean_up.sh` that will delete all the files created by the workflow. The comments in this script also describe the purpose of each file/directory it deletes.

PW cloud clusters are elastic; after a few minutes, any idle worker nodes are
released so they don't add to the cost of running the cluster.  However, since
spinning up worker nodes can take a few minutes, it can be nice to keep the
cluster "warmed up" so that the nodes are ready for a quick succession of 
tests.  A simple way to keep *N* nodes waiting for 999 seconds is the 
following terminal command:
```bash
srun -N <N> sleep 999
```
To cancel this holding pattern job on the nodes, type `Cntl+C` twice
(or `scancel <job_id>` based on output from `squeue`).  Then, 
immediately launch a job on those nodes without having to wait for 
them to spin up.

## Running Parsl with the FluxExecutor

Here we install Flux with Spack since there are many dependencies. 
Spack can have Conda inside it, so in `install_scripts/create_spack_env.sh`, 
the `miniconda3` module is installed and Parsl + Parsl
dependencies can be installed there. An example for installing Flux
is in `./install_scripts/step_01a_install_with_Spack.sh`.  I haven't set
up a Spack mirror yet, so instead I tar the Spack directory and redeploy
Spack (and its Flux and Parsl) with `./install_scripts/step_02_redeploy_Spack.sh`.

The Conda environment in Spack may be fragile; I broke it and had to reinstall
Conda (e.g. `spack uninstall miniconda3` and then `spack install miniconda3`)
after running `conda init bash`.  What has worked for me so far is to install 
everything in the `base` environment of the Conda in Spack, e.g.:
```bash
./create_spack_env.sh
spack load miniconda3
conda install -c conda-forge parsl
conda install sqlalchemy
conda install sqlalchemy-utils
pip install parsl[monitoring]
```
(`which pip` shows that this `pip` is the one inside the Conda env inside Spack.)

I've also noticed that Conda doesn't work if you `spack load flux-sched` **after**
`spack load miniconda3`. Instead, always `spack load miniconda3` after all the other
load operations. Also, it looks like once Flux is built, we may not need to activate
the newer version of gcc with `scl enable devtoolset-7 bash`.


