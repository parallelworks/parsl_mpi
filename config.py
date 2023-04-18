from parsl.config import Config
from parsl.channels import SSHChannel
from parsl.providers import LocalProvider, SlurmProvider, PBSProProvider
from parsl.executors import HighThroughputExecutor
from parsl.addresses import address_by_hostname
from parsl.launchers import SimpleLauncher

import os
import json
import argparse
import shutil

# parsl_utils is cloned at runtime
import parsl_utils
from parsl_utils.data_provider.rsync import PWRSyncStaging
from parsl_utils.data_provider.gsutil import PWGsutil
from parsl_utils.data_provider.s3 import PWS3

def read_args():
    parser = argparse.ArgumentParser()
    parsed, unknown = parser.parse_known_args()
    for arg in unknown:
        if arg.startswith(("-", "--")):
            parser.add_argument(arg, default="", nargs="?")
    pwargs = vars(parser.parse_args())
    return pwargs

pwargs = read_args()

# Need to name the job to be able to remove it with clean_resources.sh!
job_number = os.getcwd().split('/')[-1]

with open('executors.json', 'r') as f:
    exec_conf = json.load(f)

for label, executor in exec_conf.items():
    for k, v in executor.items():
        if type(v) == str:
            exec_conf[label][k] = os.path.expanduser(v)

# Define HighThroughputExecutors
executors = []
for exec_label, exec_conf_i in exec_conf.items():
    
    # Set default values:
    if 'SSH_CHANNEL_SCRIPT_DIR' not in exec_conf_i:
        script_dir = os.path.join(exec_conf_i['RUN_DIR'], 'ssh_channel_script_dir')
    else:
        script_dir = exec_conf_i['SSH_CHANNEL_SCRIPT_DIR']
    
    if 'WORKER_LOGDIR_ROOT' not in exec_conf_i:
        worker_logdir_root = os.path.join(exec_conf_i['RUN_DIR'], 'worker_logdir_root')
    else:
        worker_logdir_root =  exec_conf_i['WORKER_LOGDIR_ROOT']

    # To support kerberos:
    import shutil
    ssh_path = shutil.which('ssh')
    if 'kerberos' in ssh_path.split('/'):
        gssapi_auth = True
    else:
        gssapi_auth = False

    channel = SSHChannel(
        hostname = exec_conf_i['HOST_IP'],
        username = exec_conf_i['HOST_USER'],
        # Full path to a script dir where generated scripts could be sent to
        script_dir = script_dir,
            key_filename = '/home/{PW_USER}/.ssh/pw_id_rsa'.format(
            PW_USER = os.environ['PW_USER']
        ),
        gssapi_auth = gssapi_auth
    )

    # Define worker init:
    # - export PYTHONPATH={run_dir} is needed to use custom staging providers
    worker_init = 'export PYTHONPATH={run_dir}; bash {workdir}/pw/remote.sh; bash {workdir}/pw/.pw/remote.sh; source {conda_sh}; conda activate {conda_env}; cd {run_dir}; {clean_cmd}'.format(
        workdir = exec_conf_i['WORKDIR'],
        conda_sh = os.path.join(exec_conf_i['CONDA_DIR'], 'etc/profile.d/conda.sh'),
        conda_env = exec_conf_i['CONDA_ENV'],
        run_dir = exec_conf_i['RUN_DIR'],
        clean_cmd = "ps -x | grep worker.pl | grep -v grep | awk '{print $1}'"
    )

    # Data provider:
    # One instance per executor
    storage_access = [ 
        PWRSyncStaging(exec_label),
        PWGsutil(exec_label),
        PWS3(exec_label)
    ]

    # Define provider
    if 'PBSProProvider' in exec_conf_i:
        provider = PBSProProvider(
            **json.loads(exec_conf_i['PBSProProvider']),
            worker_init = worker_init,
            channel = channel

        )

    elif 'SlurmProvider' in exec_conf_i:
        provider = SlurmProvider(
            **json.loads(exec_conf_i['SlurmProvider']),
            worker_init = worker_init,
            channel = channel,
            launcher = SimpleLauncher(),
            parallelism = float(json.loads(exec_conf_i['SlurmProvider'])['nodes_per_block'])
        )
    else:
        # Need to overwrite the default worker_init since we don't want to run remote.sh in this case
        worker_init = 'export PYTHONPATH={run_dir}; source {conda_sh}; conda activate {conda_env}; cd {run_dir}'.format(
            conda_sh = os.path.join(exec_conf_i['CONDA_DIR'], 'etc/profile.d/conda.sh'),
            conda_env = exec_conf_i['CONDA_ENV'],
            run_dir = exec_conf_i['RUN_DIR']
        )

        provider = LocalProvider(
            worker_init = worker_init,
            channel = channel
        )

    executors.append(
        HighThroughputExecutor(
            worker_ports=((
                int(exec_conf_i['WORKER_PORT_1']), 
                int(exec_conf_i['WORKER_PORT_2'])
            )),
            label = exec_label,
            worker_debug = True,             # Default False for shorter logs
            working_dir =  exec_conf_i['RUN_DIR'],
            worker_logdir_root = worker_logdir_root,
            address = exec_conf_i['ADDRESS'],
            provider = provider,
            storage_access = storage_access
        )
    )
    
if 'parsl_retries' in pwargs:
    retries = int(pwargs['parsl_retries'])
    from . import retry_handler
    retry_handler = retry_handler.retry_handler
else:
    retries = 0
    retry_handler = None

if len(executors) > 1:
    config = Config(
        retries = retries,
        retry_handler = retry_handler,
        executors = executors
    )
else:
    from parsl.monitoring.monitoring import MonitoringHub
    executor_address = list(exec_conf.values())[0]['ADDRESS']
    config = Config(
        retries = retries,
        retry_handler = retry_handler,
        executors = executors,
        monitoring = MonitoringHub(
            hub_address = executor_address,
            monitoring_debug = False,
            workflow_name = str(job_number),
            logging_endpoint = 'sqlite:////pw/.monitoring.db',
            resource_monitoring_enabled = False,
        )
    )
