<<<<<<< HEAD
# PARSL MPI

This workflow runs OpenMPI hello world jobs using Parsl. The OpenMPI hello world code is defined in `mpitest.c` and, when compiled and executed, prints the hostname and rank in the format below:

```
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0001, rank 0 out of 2 processors
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0002, rank 1 out of 2 processors
```

## Motivation

High performance computing workflows may depend on the orchestration of many 
diverse applications: ensemble members, data-assimilation, pre-/post-processing, 
visualization tools, and most recently, machine learning. To enable community 
involvement, these complex workflows need to be automated, users need to be able 
to manage “live” workflows (i.e. as they run) in a straightforward manner, and 
the workflows need to be portable so they can run in a wide range of compute 
environments (e.g. on-premise clusters and cloud). Separately, over the last decades, 
the workflow community has developed different workflow systems for expressing 
automation and control but the majority of this work has been to support 
high-throughput workflows: i.e. 1000’s of single node tasks. Workflow fabrics’ 
support for the coordination and management of multi-node tasks (i.e. large MPI 
jobs) is less widespread and documented. Here, we aim to help bridge this 
knowledge gap with a curated set of templates and examples that demonstrate 
the automation and control of workflows that launch MPI tasks with existing 
workflow fabrics.  This project is working toward the development of a proof of 
concept workflow that manages MPI tasks and has a similar topology as real-world 
weather forecasting operational workflows. By making these documented and evolving 
building blocks available to the community, we hope to empower users to work in 
the “MPI task niche” within the broader landscape of workflow fabrics.

## Organization

The files in the top level of this repo are designed to be launched from the Parallel Works
platform as workflows. The `run_on_cluster` subdirectory is a starting point for 
experimentation/debugging/development because it provides scripts that are designed to
run directly on a cluster (i.e. manually) rather than being launched via a workflow.

In particular, the `run_on_cluster` directory archives experimentation using Parsl
and Flux together (via Parsl's `FluxExecutor`). As we gain additional experience with
this framework, Flux will be integrated into PW-launched workflows at the top level.

## Apps

Parsl apps are defined as `bash_app` decorated functions in the `workflow_apps.py` script. The OpenMPI code is compiled by `compile_mpi_hello_world_ompi` and executed by `compile_mpi_hello_world_ompi_localprovider` or `compile_mpi_hello_world_ompi_slurmprovider`, depending on the selected provider (see execution), multiple times in parallel as defined by the `repeats` workflow input parameter. 

## Execution

The workflow can be executed using the [LocalProvider](https://parsl.readthedocs.io/en/stable/stubs/parsl.providers.LocalProvider.html) or the [SlurmProvider](https://parsl.readthedocs.io/en/stable/stubs/parsl.providers.SlurmProvider.html). The [parsl_utils](https://github.com/parallelworks/parsl_utils) repository is used to integrate Parsl on the PW clusters. This repository defines the Parsl configuration object from a JSON file. Sample JSON files are provided in the `executors` directory. The selected Parsl provider is started on the controller node of the SLURM cluster using the Parsl [SSHChannel](https://parsl.readthedocs.io/en/stable/stubs/parsl.channels.SSHChannel.html). 

### LocalProvider

The nodes for the jobs are allocated with the `sbatch -W` command in the 
`run_mpi_hello_world_ompi` function. The workflow generates the `#SBATCH`
options from the SLURM parameters in the `workflow.xml` file. The name of these parameters starts with `slurm_` to indicate that they correspond to [SLURM sbatch options](https://slurm.schedmd.com/sbatch.html). 

### SlurmProvider

The nodes for the jobs are allocated by the pilot job and the MPI code is executed directly on these without using a SLURM command. 


## MPI Parsl Challenges

Running MPI jobs using Parsl's [SlurmProvider](https://parsl.readthedocs.io/en/stable/stubs/parsl.providers.SlurmProvider.html) can be challenging as discussed in [this video](https://www.youtube.com/watch?v=0V4Hs4kTyJs&t=398s). Here are a list of challenges:

### 1. No Control Over Slurm Parameters 
If you launch the command inside a `bash_app` it will return the following error:
```
 mpirun -np 2 mpitest
 ```
 
 ```
 There are not enough slots available in the system to satisfy the 2
slots that were requested by the application:
 ```
 
 The reason for this is that it uses the SLURM environment variables that Parsl sets for the pilot job, in which `--ntasks-per-node=1` is hardcoded. 
 
One solution would be to overwrite these variables on the bash app itself.

### 2. Cannot Get More Than 1 Node Per Worker
No combination of `cores_per_worker`, `nodes_per_block` and `cores_per_node` returns the right MPI output. The only combination that works is shown in the `run_on_cluster/slurmprovider.py` config object. It requires the following setup:
1. Use the `SimpleLauncher`
2. Set `nodes_per_block` to the desired number of nodes per MPI task
3. Set `cores_per_worker` to the number of cores in a single node
4. Set `parallelism` to the desired number of nodes per MPI task
=======
This repository had been made for the sole purpose of testing DVC. I'm pretty sure I keep destroying my other one so imma start trying to be safer lol.
>>>>>>> testing-repo/main
