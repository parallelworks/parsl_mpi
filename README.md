# PARSL MPI
This workflow runs MPI hello world jobs using Parsl. The jobs return a hello world with the processor name and rank:

```
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0001, rank 0 out of 2 processors
Hello world from processor alvaro-gcpslurmv2dev-00091-1-0002, rank 1 out of 2 processors
```

This workflow uses [parsl_utils](https://github.com/parallelworks/parsl_utils) to run on PW clusters.

## MPI Parsl Challenges
Running MPI jobs in Parsl can be challenging as discussed in [this video](https://www.youtube.com/watch?v=0V4Hs4kTyJs&t=398s). Here are a list of challenges:

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