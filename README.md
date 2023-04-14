# PARSL MPI
This workflow runs OpenMPI hello world jobs using Parsl. The OpenMPI hello world code is defined in `mpitest.c` and, when compiled and executed, prints the hostname and rank in the format below:

```
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0001, rank 0 out of 2 processors
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0002, rank 1 out of 2 processors
```

The OpenMPI code is compiled and executed in the Parsl `bash_app` decorated functions `compile_mpi_hello_world_ompi` and `run_mpi_hello_world_ompi`, respectively. The `run_mpi_hello_world_ompi` is executed multiple times in parallel as defined by the `repeats` workflow input parameter. 

## Execution
This workflow uses the [parsl_utils](https://github.com/parallelworks/parsl_utils) repository to run on PW clusters. This repository defines the Parsl configuration object from a JSON file. A sample JSON file is provided in `sample_executors.json`. This file tells the `parsl_utils` repository to use the Parsl [LocalProvider](https://parsl.readthedocs.io/en/stable/stubs/parsl.providers.LocalProvider.html) to execute the workflow. The LocalProvider is started on the controller node of the SLURM cluster using the Parsl [SSHChannel](https://parsl.readthedocs.io/en/stable/stubs/parsl.channels.SSHChannel.html). The nodes for the jobs are allocated with the `sbatch -W` command in the `run_mpi_hello_world_ompi` function. The workflow generates the the `#SBATCH` options from the SLURM parameters in the `workflow.xml` file. The name of these parameters starts with `slurm_` to indicate that they correspond to [SLURM sbatch options](https://slurm.schedmd.com/sbatch.html). 

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