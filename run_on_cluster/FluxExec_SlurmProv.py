# Before running this script,
# spack load intel-oneapi-mpi
# spack load flux-sched
# export I_MPI_FABRICS=shm:ofi

import parsl
from parsl.app.app import bash_app
print(parsl.__version__, flush = True)
from parsl.data_provider.files import File

from parsl.config import Config
from parsl.providers import SlurmProvider
from parsl.executors import FluxExecutor
from parsl.launchers import SimpleLauncher
from parsl.launchers import SrunLauncher
from parsl.channels import LocalChannel

# Need os here to create config
import os

################
# DESCRIPTION  #
################
"""
This is an MPI Hello World test using parsl. It has two apps:
1. compile_mpi_hello_world_ompi: To compile the MPI code
2. run_mpi_hello_world_ompi: To execute the MPI code

The test has the following goals:
1. Use multiple nodes per execution of the "run" app 
2. Execute the the "run" apps in parallel (repeats > 1)
3. Every "run" app execution returns hello from all the nodes and cores on the
   nodes without overlapping with the other "run" app executions.

For example, with the input values below (see inputs section) the output is:
  Results for case: 0
  Hello world from processor alvaro-gcpv2-00036-1-0001, rank 0 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0001, rank 1 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0002, rank 2 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0002, rank 3 out of 4 processors

  Results for case: 1
  Hello world from processor alvaro-gcpv2-00036-1-0003, rank 1 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0003, rank 0 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0004, rank 2 out of 4 processors
  Hello world from processor alvaro-gcpv2-00036-1-0004, rank 3 out of 4 processors

Where the first "run" app runs on the nodes alvaro-gcpv2-00036-1-0001 and 
alvaro-gcpv2-00036-1-0002, and the second "run" app runs on the nodes
alvaro-gcpv2-00036-1-0003 and alvaro-gcpv2-00036-1-0004. Note that these nodes
only have two cores (cores_per_node=2) and both apps use all the cores in the nodes.

Also, note that a sleep command is included in the "run" app to give the SLURM resource
manager enough time to provision all the resources and prevent Parsl from running all
the apps on the first provisioned block of resources. 

To satisfy the goals above, we defined an executor with as many nodes per block as 
nodes per "run" app. This way, every block can only execute one "run" app at once. 
However, to get this to the following "tricks" were used:
1. Override the "SLURM_TASKS_PER_NODE" environment variable on the "run" app
2. Set the "parallelism" parameter of the SlurmProvider to the number of nodes 
   per block (nodes_per_block) (>1).

We understand that (1) is required because Parsl hardcodes the SLURM parameter
--ntasks-per-node to 1. However, we do not understand why (2) is required. If
parallelism is set to 1 then only repeats/noces_per_block "run" apps are executed
in parallel. For example, if repeats=4 and nodes_per_block=2 then only 2 "run"
apps are executed in parallel. 

We tried to set the cores_per_worker parameter in the HighThroughputExecutor to
(cores_per_node x nodes_per_block) in an attempt to get one worker per two nodes.
However, if this parameter is increased beyond the "cores_per_node" value the blocks
hang in "pending" state (0 connected workers) and never reach the "running" state.
"""

##########
# INPUTS #
##########
mpi_dir = '/contrib/alvaro/ompi/'
repeats = 12
cores_per_node = 2
nodes_per_block = 3
np = cores_per_node * nodes_per_block
partition = "small"
#partition = "cs"

##########
# CONFIG #
##########

exec_label = 'myFluxExecSlurmProv'

config = Config(
    executors = [
        FluxExecutor(
            working_dir =  os.getcwd()+"/FluxExecWorkDir",
            label = exec_label,
            flux_executor_kwargs = {"threads": cores_per_node},
            flux_path = None,
            #launch_cmd='srun --tasks-per-node=1 -c1 ' + FluxExecutor.DEFAULT_LAUNCH_CMD,
            launch_cmd = 'srun --ntasks=3 --ntasks-per-node=2 {flux} start --verbose=3 -o,-v {python} {manager} {protocol} {hostname} {port}',
            #launch_cmd = "{flux} start -v {python} {manager} {protocol} {hostname} {port}",
            provider = SlurmProvider(
                channel = LocalChannel(),
                partition = partition,             #SBATCH --partition
                nodes_per_block = nodes_per_block, #SBATCH --nodes
                cores_per_node = cores_per_node,   #SBATCH --cpus-per-task
                min_blocks = 0,
                max_blocks = 10,
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
    #export OMPI_DIR={ompi_dir}
    #export PATH=$OMPI_DIR/bin:$PATH
    #export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
    #export MANPATH=$OMPI_DIR/share/man:$MANPATH
    # Parsl worker_init is ignored, so do it here
    #==============When using Spack===================
    #source /home/sfgary/parsl_flux/spack/share/spack/setup-env.sh
    #source /scratch/sfg3866/flux/spack/share/spack/setup-env.sh
    #spack load openmpi
    #spack load flux-sched
    #spack load miniconda3
    #==============When using Conda==================
    #source /home/sfgary/pw/miniconda3/etc/profile.d/conda.sh
    #conda activate parsl-mpi
    mpicc -o mpitest {mpi_c}
    flux resource list
    '''.format(
        ompi_dir = ompi_dir,
        mpi_c = inputs[0].path
    )


@bash_app(executors=[exec_label])
def run_mpi_hello_world_ompi(np: int, ompi_dir: str,
                             inputs: list = None, outputs: list = None, 
                             stdout: str ='std.out', stderr: str = 'std.err',
                             parsl_resource_specification={"num_tasks": 6, "num_nodes": 3}):
    import os
    """
    Runs the binary directly
    """
    return '''
    # Override Parsl SLURM parameter
    # Without the sleep command below this app runs very fast. Therefore, when launched multiple times
    # in parallel (nrepeats > 1) it ends up on the same group of nodes. Note that the goal of this 
    # experiment is to return the host names of the different nodes running the app. 
    #==============When using Spack==================
    #source /home/sfgary/parsl_flux/spack/share/spack/setup-env.sh
    #source /scratch/sfg3866/flux/spack/share/spack/setup-env.sh
    #spack load flux-sched
    #spack load miniconda3
    #==============When using Conda==================
    #source /home/sfgary/pw/miniconda3/etc/profile.d/conda.sh
    #conda activate parsl-mpi
    #sleep 10
    #unset I_MPI_FABRICS
    #mpirun -np {np} mpitest > {output}
    flux resource list 
   ./mpitest > {output}
'''.format(
        np = np,
        ompi_dir = ompi_dir,
        output = outputs[0].path
    )

# Was inside the app:
    # Override Parsl SLURM parameter                                                   
    # In Parsl the ntasks-per-node parameter is hardcoded to 1
    #export SLURM_TASKS_PER_NODE="{SLURM_TASKS_PER_NODE}(x{SLURM_NNODES})"            
    #export OMPI_DIR={ompi_dir}
    #export PATH={ompi_dir}/bin:$PATH    

# Was iniside the .format()
    #SLURM_NNODES = os.environ['SLURM_NNODES'],
    #SLURM_TASKS_PER_NODE = int(int(np) / int(os.environ['SLURM_NNODES'])),

############
# WORKFLOW #
############
mpi_c_source_code = './mpitest.c'

# Write file <mpi_c_source_code> if it does not exist
if not os.path.isfile(mpi_c_source_code):
    with open(mpi_c_source_code, "w") as f:
        f.write("#include <mpi.h>\n")
        f.write("#include <stdio.h>\n")
        f.write("int main(int argc, char** argv) {\n")
        f.write("  MPI_Init(NULL, NULL);\n")
        f.write("  int world_size;\n")
        f.write("  MPI_Comm_size(MPI_COMM_WORLD, &world_size);\n")
        f.write("  int world_rank;\n")
        f.write("  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);\n")
        f.write("  char processor_name[MPI_MAX_PROCESSOR_NAME];\n")
        f.write("  int name_len;\n")
        f.write("  MPI_Get_processor_name(processor_name, &name_len);\n")
        f.write("  printf(\"Hello world from processor %s, rank %d out of %d processors\\n\",processor_name, world_rank, world_size);\n")
        f.write("  MPI_Finalize();\n")
        f.write("}\n")

if __name__ == '__main__':
    print('Loading Parsl Config', flush = True)
    parsl.load(config)

    print('\n\nCompiling test', flush = True)
    compile_fut = compile_mpi_hello_world_ompi(
        mpi_dir,
        inputs = [File(mpi_c_source_code)]
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

