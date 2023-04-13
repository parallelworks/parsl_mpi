import sys, os, json, time
from random import randint
import argparse

import parsl
from parsl.app.app import python_app
print(parsl.__version__, flush = True)

import parsl_utils
from parsl_utils.config import config, exec_conf, read_args
from parsl_utils.data_provider import PWFile

from workflow_apps import compile_mpi_hello_world_ompi, run_mpi_hello_world_ompi


if __name__ == '__main__':
    print('Loading Parsl Config', flush = True)
    parsl.load(config)
    args = read_args()

    print('\n\nCompiling test', flush = True)
    compile_fut = compile_mpi_hello_world_ompi(
        args['mpi_dir'],
        inputs = [
            PWFile(
                url = './mpitest.c',
                local_path = './mpitest.c'
            )
        ],
    )

    run_futs = []
    for i in range(int(args['repeats'])):
        print('\n\nRunning case: ' + str(i), flush = True)
        run_fut = run_mpi_hello_world_ompi(
            args['np'], args['mpi_dir'],
            inputs = [compile_fut],
            outputs = [
                PWFile(
                    url = './hello-' + str(i) + '.out' ,
                    local_path = './hello-' + str(i) + '.out' 
                )
            ],
            stdout = 'run-' + str(i) + '.out',
            stderr = 'run-' + str(i) + '.err'
        )
        run_futs.append(run_fut)

    for fut in run_futs:
        fut.result()

