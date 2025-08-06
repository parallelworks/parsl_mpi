import parsl
print(parsl.__version__, flush = True)

from parsl.config import Config
from parsl.providers import SlurmProvider
from parsl.executors import HighThroughputExecutor
from parsl.launchers import SimpleLauncher

# Need os here to create config
import os

################
# DESCRIPTION  #
################
"""
Parsl configuration for use with parsl-perf
SLURM cluster
"""

##############
# Parameters #
##############
cores_per_node = 1
nodes_per_block = 1
partition = "normal"
exec_label = 'slurm_provider'

##########
# CONFIG #
##########

config = Config(
    executors = [
        HighThroughputExecutor(
            label = exec_label,
            cores_per_worker =  cores_per_node,
            worker_debug = True,            
            working_dir =  os.getcwd(),
            worker_logdir_root = os.getcwd(),
            provider = SlurmProvider(
                partition = partition,
                nodes_per_block = nodes_per_block,
                min_blocks = 0,
                max_blocks = 2,
                walltime ="01:00:00",
                launcher = SimpleLauncher(),
                parallelism = float(1),
                worker_init = "source /data/miniconda/etc/profile.d/conda.sh; conda activate base"
            )
        )
    ]
)

