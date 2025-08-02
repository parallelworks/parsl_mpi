import parsl
print(parsl.__version__, flush = True)

from parsl.config import Config
from parsl.providers import LocalProvider
from parsl.executors import HighThroughputExecutor
from parsl.launchers import SimpleLauncher

# Need os here to create config
import os

################
# DESCRIPTION  #
################
"""
Parsl configuration for use with parsl-perf
Local node only
"""

##############
# Parameters #
##############
cores_per_node = 2
nodes_per_block = 2
exec_label = 'local_provider'

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
            provider = LocalProvider(
                nodes_per_block = nodes_per_block,
                min_blocks = 0,
                max_blocks = 2,
                parallelism = float(1),
                worker_init = "source /home/sfg/work_git/miniconda/etc/profile.d/conda.sh; conda activate base"
            )
        )
    ]
)

