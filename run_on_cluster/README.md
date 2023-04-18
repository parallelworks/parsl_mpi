This directory contains scripts that can run directly on a cluster. The goal
is to isolate the MPI part from the other features that are handled by parsl_utils:
1. Data transfer
2. Multihost execution (multi cluster)
3. Monitoring
4. Python dependencies installation
5. SSH tunnels
6. etc