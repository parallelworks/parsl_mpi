from parsl.app.app import bash_app
import parsl_utils

# PARSL APPS:


@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=['myexecutor_1'])
def compile_mpi_hello_world_ompi(ompi_dir, inputs = [], stdout='compile.out', stderr = 'compile.err'):
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
def run_mpi_hello_world_ompi(srun_cmd, np, ompi_dir, inputs = [], outputs = [], stdout='std.out', stderr = 'std.err'):
    """
    Runs the binary using the specified srun command and number of processors
    """
    return '''
    export OMPI_DIR={ompi_dir}
    export PATH=$OMPI_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
    export MANPATH=$OMPI_DIR/share/man:$MANPATH
    {srun_cmd} mpirun -n {np} mpitest > {output}
    '''.format(
        srun_cmd = srun_cmd,
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].local_path
    )
