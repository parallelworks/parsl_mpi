from parsl.app.app import bash_app
import parsl_utils


@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=['myexecutor_1'])
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
        mpi_c = inputs[0].local_path
    )


@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=['myexecutor_1'])
def run_mpi_hello_world_ompi_localprovider(case: str, sbatch_header: str, np: int, ompi_dir: str,
                             inputs: list = None, outputs: list = None, 
                             stdout: str ='std.out', stderr: str = 'std.err'):
    """
    Runs the binary using sbatch
    NOTES:
      - Using srun results in duplication of the output lines, see https://github.com/parallelworks/issues/issues/1102
    """
    return '''
cat > run_mpi_hello_world_ompi_{case}.sh <<EOF
#!/bin/bash
{sbatch_header}
export OMPI_DIR={ompi_dir}
export PATH={ompi_dir}/bin:$PATH

mpirun -n {np} mpitest > {output}
EOF
chmod +x run_mpi_hello_world_ompi_{case}.sh
sbatch -W run_mpi_hello_world_ompi_{case}.sh
'''.format(
        case = case,
        sbatch_header = sbatch_header,
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].local_path
    )


@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=['myexecutor_1'])
def run_mpi_hello_world_ompi_slurmprovider(np: int, ompi_dir: str,
                             inputs: list = None, outputs: list = None, 
                             stdout: str ='std.out', stderr: str = 'std.err'):
    import os
    """
    Runs the binary directly
    """
    return '''
    # Override Parsl SLURM parameter
    # In Parsl the ntasks-per-node parameter is hardcoded to 1
    env | grep SLURM > SLURM_ENV.txt
    export SLURM_TASKS_PER_NODE="{SLURM_TASKS_PER_NODE}(x{SLURM_NNODES})"
    export OMPI_DIR={ompi_dir}
    export PATH={ompi_dir}/bin:$PATH
    mpirun -n {np} mpitest > {output}
'''.format(
        SLURM_NNODES = os.environ['SLURM_NNODES'],
        SLURM_TASKS_PER_NODE = int(int(np) / int(os.environ['SLURM_NNODES'])),
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].local_path
    )
