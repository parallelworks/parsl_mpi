from parsl.app.app import bash_app
import parsl_utils

# PARSL APPS:


@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=['myexecutor_1'])
def compile_mpi_hello_world_ompi(ompi_dir, inputs = [], stdout='compile.out', stderr = 'compile.err'):
    """
    Sample bash app that runs in myexecutor_1 (defined in the Parsl config). The argument fut is a future
    from a different app and is only used to create a dependency (run this app after the other app).
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
def run_mpi_hello_world_ompi(np, ompi_dir, inputs = [], outputs = [], stdout='std.out', stderr = 'std.err'):
    """
    Sample bash app that runs in myexecutor_1 (defined in the Parsl config). The argument fut is a future
    from a different app and is only used to create a dependency (run this app after the other app).
    """
    return '''
    export OMPI_DIR={ompi_dir}
    export PATH=$OMPI_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
    export MANPATH=$OMPI_DIR/share/man:$MANPATH
    mpirun -n {np} mpitest > {output}
    '''.format(
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].local_path,
    )
