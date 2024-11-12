# Set persistent environment variables
# for the OpenFOAM configuration to run.

# Simulation size/configuration
# NPROC_MPI=12 is the default, it
# must always be NTASKS x NNODE
# RUN_TIME at 7 s is the default,
# this takes a very long time. Even
# a 2 s run time takes about 9 mins
# on 40 CPU (single node).
# DOMAIN_DECOMP is default = (2 2 3)
# It must mulitply to NPROC_MPI, e.g.
# 2 x 2 x 3 = 12.

#==============================
# DEFAULTS
#export NTASKS_PER_NODE=6
#export NNODES=2
#export NPROCS_MPI=12
#export RUN_TIME=0.2
#export DOMAIN_DECOMP="(2 2 3)"

#===============================
# Configuration for using a 
# single Azure HC44rs through sbatch
#export NTASKS_PER_NODE=28
#export NNODES=1
#export NPROCS_MPI=28
#export RUN_TIME=0.5
#export DOMAIN_DECOMP="(2 2 7)"

#===============================
# Configuration for using a
# single Azure HC44rs locally (no sbatch)
#export NTASKS_PER_NODE=40
#export NNODES=1
#export NPROCS_MPI=40
#export RUN_TIME=0.2
#export DOMAIN_DECOMP="(2 4 5)"

#==============================
# Configuration for using
# 6 Azure HC44rs nodes
# Runs in 72s for 0.2s simulation time
#export NTASKS_PER_NODE=24
#export NNODES=6
#export NPROCS_MPI=144
#export RUN_TIME=0.2
#export DOMAIN_DECOMP="(4 6 6)"

#============================
# Configuration for using 10
# nodes with 2 CPU each
# (i.e. small workers)
export NTASKS_PER_NODE=10
export NNODES=2
#----------------------
# Shouldn't be necessary as SLURM can compute 
# this from NTASKS_PER_NODE x NNODES but needed
# for OpenFOAM configuration (step3).
export NPROCS_MPI=20
#----------------------
export RUN_TIME=0.2
export DOMAIN_DECOMP="(2 2 5)"

# Done

