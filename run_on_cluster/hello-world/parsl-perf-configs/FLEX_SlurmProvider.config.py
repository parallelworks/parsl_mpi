# Before running this script:
# spack load flux-sched
# spack load py-parsl

import parsl
print(parsl.__version__, flush = True)

from parsl.config import Config
from parsl.providers import SlurmProvider
from parsl.executors import FluxExecutor
from parsl.launchers import SimpleLauncher

# Need os here to create config
import os

################
# DESCRIPTION  #
################

##############
# Parameters #
##############
cores_per_node = 4
nodes_per_block = 2
partition = "small"

##########
# CONFIG #
##########

exec_label = 'FluxExecSlurmProv'

config = Config(
    executors = [
        FluxExecutor(
            working_dir =  os.getcwd()+"/FluxExecWorkDir",
            label = exec_label,
            flux_executor_kwargs = {"threads": cores_per_node},
            flux_path = None,
            #launch_cmd='srun --tasks-per-node=1 -c1 ' + FluxExecutor.DEFAULT_LAUNCH_CMD,
            #launch_cmd = 'srun --ntasks=3 --ntasks-per-node=2 {flux} start --verbose=3 -o,-v {python} {manager} {protocol} {hostname} {port}',
            launch_cmd = 'srun {flux} start --verbose=3 -o,-v {python} {manager} {protocol} {hostname} {port}',
            #launch_cmd = "{flux} start -v {python} {manager} {protocol} {hostname} {port}",
            provider = SlurmProvider(
                partition = partition,             #SBATCH --partition
                nodes_per_block = nodes_per_block, #SBATCH --nodes
                cores_per_node = cores_per_node,   #SBATCH --cpus-per-task
                min_blocks = 0,
                init_blocks = 1,
                max_blocks = 1,
                walltime ="01:00:00",
                #launcher = SrunLauncher(),
                # Choose SimpleLauncher to be able to set srun CLI flags (e.g. --ntasks-per-node != 1)
                launcher = SimpleLauncher(),
                parallelism = 1, #float(nodes_per_block)
                exclusive = False
                #worker_init = 'source ~/pw/miniconda3/etc/profile.d/conda.sh; conda activate parsl-mpi'
                #worker_init = 'spack load flux-sched; spack load miniconda3'
            )
        )
    ]
)

