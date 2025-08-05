import parsl
print(parsl.__version__, flush = True)

from parsl.config import Config
from parsl.providers import KubernetesProvider
from parsl.executors import HighThroughputExecutor

# Need os here to create config
import os

################
# DESCRIPTION  #
################
"""
Parsl configuration for use with parsl-perf
Kubernetes cluster
"""

##############
# Parameters #
##############
max_cpu = 1
cores_per_worker = 1
nodes_per_block = 1
namespace = "default"
exec_label = 'parsl-perf_kubernetes_provider'

##########
# CONFIG #
##########

config = Config(
    executors = [
        HighThroughputExecutor(
            label = exec_label,
            cores_per_worker =  cores_per_worker,
            worker_debug = True,            
            working_dir =  os.getcwd(),
            worker_logdir_root = os.getcwd(),
            provider = KubernetesProvider(
                namespace = namespace,
                image = "stefanfgary/pythonparsl",
                nodes_per_block = nodes_per_block,
                min_blocks = 0,
                init_blocks = 1,
                max_blocks = 1,
                max_cpu = max_cpu,
                max_mem = "2Gi",
                parallelism = float(1),
                run_as_non_root = True,
                #worker_init = "pip install parsl[kubernetes,monitoring]",
                pod_name = exec_label+"_pod"
            )
        )
    ]
)

