# Run OpenFOAM from the command line

These scripts set up an end to end OpenFOAM run (`cyclone` demo). Several
key configuration environment variables are set in `openmpi_env.sh`. OpenFOAM
is run via a Singularity container in either single or multiple nodes.

+ `step_00_lmod_reset.sh` is currently only useful for developement testing with high performance networking on some CSPs.
+ `step_01_build_container.sh` is used to copy the OpenFOAM container to the cluster.
+ `step_02_install_openmpi.sh` installs OpenMPI on the cluster.
+ `step_03_setup_openfoam.sh` copies the `cyclone` OpenFOAM demo from the container and modifies it slightly based on the specifications in `openmpi_env.sh`.
+ `step_04_run_container_hello.sh` tests a simple `hello-world` with MPI in containers across multiple nodes.
+ `step_05_run_openfoam_singlehost.sh` runs the `cyclone` demo on a **single node**.
+ `step_06_run_openfoam_multihost.sh` runs the `cyclone` demo on **multiple nodes**.

