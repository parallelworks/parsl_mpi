#=====================================
# Send an MPI job to an MPI-enabled
# Globus Compute endpoint.
#
# Setup is currently manual:
# 1) run ./install/create_conda_env.sh on both client and cluster
# 2) authenticate to Globus on both client and cluster
# 3) if needed, ensure slurm-devel and OpenMPI are on the cluster
# 4) start the Globus Compute endpoint on the cluster, with ./install/start_endpoint.sh
# 5) run this script on the client to send job to cluster
#
#====================================

import sys
from globus_compute_sdk import Client, Executor

# Start connection to Globus within Python.
# This will check for service account's env vars 
# or manual Globus auth tokens.
gcc = Client()

# Get list of current endpoints for whoever you
# have authenticated as.
endpts = gcc.get_endpoints()

# Get the UUID of the first endpoint (ASSUME USING THIS ONE).
endpoint_id = endpts[1]['uuid']
print('Using endpoint: '+endpoint_id)

# Start a Globus Compute Executor here (i.e. on the client)
ex = Executor(endpoint_id=endpoint_id)

# This test is used to simply confirm whether the endpoint is online
def platinfo(resource_specification={}):
    import platform
    return platform.uname()

rs = {'num_nodes':2, 'num_ranks':4}
print(rs.keys())

future = ex.submit(platinfo, resource_specification=rs)

print(future.done())

print(future.result())

print('Done!')

