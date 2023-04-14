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

from dataclasses import dataclass, fields
from typing import Optional

@dataclass
class SbatchOptions:
    account: Optional[str] = None
    nodes: Optional[int] = None
    job_name: Optional[str] = None
    ntasks_per_node: Optional[int] = None
    output: Optional[str] = None
    partition: Optional[str] = None
    
    @property
    def header(self):
        option_names = [f.name for f in fields(self)]
        header_str = ''
        for oname in option_names:
            oval = getattr(self, oname)
            if oval:
                header_str += '\n#SBATCH --' + oname.replace('_','-') + '=' + str(oval) 

        return header_str


if __name__ == '__main__':
    print('Loading Parsl Config', flush = True)
    parsl.load(config)
    args = read_args()
    # Dictionary with only the slurm parameters. These are the parameters that start with slurm_
    # in the workflow.xml file. The slurm_ part is removed so that {'slurm_nodes': 1} becomes
    # {'nodes': 1}
    slurm_args = {k.replace("slurm_", ""): v for k, v in args.items() if k.startswith("slurm_")}

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
        
        sbatch_options = SbatchOptions(
            **slurm_args, 
            job_name = f'run_mpi_hello_world_ompi_{i}',
            output = f'run_mpi_hello_world_ompi_{i}.out',
        )

        run_fut = run_mpi_hello_world_ompi(
            str(i), sbatch_options.header, args['np'], args['mpi_dir'],
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

    for i,fut in enumerate(run_futs):
        print('\n\nResults for case: ' + str(i), flush = True)
        with open(fut.outputs[0].result(), 'r') as f:
            print(f.read())

