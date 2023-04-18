import sys, os, json, time
from random import randint
import argparse

import parsl
from parsl.app.app import bash_app
print(parsl.__version__, flush = True)
from parsl.data_provider.files import File

from parsl.config import Config
from parsl.providers import SlurmProvider
from parsl.executors import HighThroughputExecutor
from parsl.launchers import SimpleLauncher

##########
# INPUTS #
##########
mpi_dir = '/contrib/alvaro/ompi/'
repeats = 2
cores_per_node = 2
nodes_per_block = 2
np = cores_per_node * nodes_per_block
partition = "compute"

##########
# CONFIG #
##########

exec_label = 'slurm_provider'

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
                max_blocks = 10,
                walltime ="01:00:00",
                launcher = SimpleLauncher(),
                parallelism = float(nodes_per_block) 
            )
        )
    ]
)


########
# APPS #
########
@bash_app(executors=[exec_label])
def compile_mpi_hello_world_ompi(ompi_dir: str, inputs: list = None, 
                                 stdout: str ='compile.out', stderr: str = 'compile.err'):
    """
    Creates the mpitest binary in the working directory
    """
    return '''
    export OMPI_DIR={ompi_dir}
    export PATH=$OMPI_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
    export MANPATH=$OMPI_DIR/share/man:$MANPATH
    mpicc -o mpitest {mpi_c}
    '''.format(
        ompi_dir = ompi_dir,
        mpi_c = inputs[0].path
    )


@bash_app(executors=[exec_label])
def run_mpi_hello_world_ompi(np: int, ompi_dir: str,
                             inputs: list = None, outputs: list = None, 
                             stdout: str ='std.out', stderr: str = 'std.err'):
    import os
    """
    Runs the binary directly
    """
    return '''
    # Override Parsl SLURM parameter
    # In Parsl the ntasks-per-node parameter is hardcoded to 1
    export SLURM_TASKS_PER_NODE="{SLURM_TASKS_PER_NODE}(x{SLURM_NNODES})"
    export OMPI_DIR={ompi_dir}
    export PATH={ompi_dir}/bin:$PATH
    # Without the sleep command below this app runs very fast. Therefore, when launched multiple times
    # in parallel (nrepeats > 1) it ends up on the same group of nodes. Note that the goal of this 
    # experiment is to return the host names of the different nodes running the app. 
    sleep 10
    mpirun -np {np} mpitest > {output}
'''.format(
        SLURM_NNODES = os.environ['SLURM_NNODES'],
        SLURM_TASKS_PER_NODE = int(int(np) / int(os.environ['SLURM_NNODES'])),
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].path
    )


############
# WORKFLOW #
############

if __name__ == '__main__':
    print('Loading Parsl Config', flush = True)
    parsl.load(config)

    print('\n\nCompiling test', flush = True)
    compile_fut = compile_mpi_hello_world_ompi(
        mpi_dir,
        inputs = [File('./mpitest.c')]
    )

    run_futs = []
    for i in range(repeats):
        print('\n\nRunning case: ' + str(i), flush = True)
        
        # Launch MPI function
        run_fut = run_mpi_hello_world_ompi(
            np, mpi_dir,
            inputs = [compile_fut],
            outputs = [File('./hello-' + str(i) + '.out')],
            stdout = 'run-' + str(i) + '.out',
            stderr = 'run-' + str(i) + '.err'
        )
        run_futs.append(run_fut)

    for i,fut in enumerate(run_futs):
        print('\n\nResults for case: ' + str(i), flush = True)
        with open(fut.outputs[0].result(), 'r') as f:
            print(f.read())

