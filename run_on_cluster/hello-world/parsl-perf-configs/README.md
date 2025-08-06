# Parsl-perf set up notes

## Local Kubernetes cluster

## Distributed Kubernetes cluster

## Local Slurm cluster

Based on the [instructions by Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601). 
```
# Install docker-compose
#pip3 install docker-compose

# The pip version does not seem to work
# (but I was messing around with different
# Conda envs, so it may work), so try
# the manual approach based on the docs:
# https://docs.docker.com/compose/install/linux/#install-the-plugin-manually
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

# If on a PW cloud cluster head node, stop
# the SLURM daemon and database services
# because they are listening on port 6819
# which is used by the docker-compose SLURM
# cluster. There's got to be a way around this,
# but just tear things down for now.
sudo systemctl stop slurmctld.service
sudo systemctl stop slurmdbd.service

# Get the repo with the Docker-compose file:
git clone https://github.com/rancavil/slurm-cluster

# Launch the cluster and Jupyter server
# I had to change the prefix on the container
# images to rancavil/
cd slurm-cluster
docker-compose up -d

# Clean up when done
docker-compose stop
cd ..
rm -rf slurm-cluster
```
The cluster comes up, but there is something not quite right OOB - I cannot `srun`
since SLURM in the container thinks the nodes are down.  Try MELISSA instead
based on [instructions here](https://melissa.gitlabpages.inria.fr/melissa/creating-a-slurm-docker-cluster/) 
with the added advantage of a simpler cluster so it may be easier to add more nodes
to the cluster. MELISSA is, in turn, based on [slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster.git),
which I will use as the starting point:
```
# Get code and configs
https://github.com/giovtorres/slurm-docker-cluster.git

# Build (takes about 5 mins)
# Consider adding Parsl and Flux to the container.
cd slurm-docker-cluster
docker build --build-arg SLURM_TAG="slurm-21-08-6-1" -t slurm-docker-cluster:21.08.6 .

# Start cluster
docker compose up -d

# Register (says it didn't do anything?)
./register_cluster.sh

# Easy enough to add more nodes (containers) on the fly.
# Modify slurm.conf in three places - the two lists of nodes in 
# NodeName and PartitionName, and MaxNodes in PartitionName.
# Then run:
./update_slurmfiles.sh slurm.conf slurmdbd.conf
docker compose restart

# Stop
docker compose stop

# Clean up
docker compose down -v
```

## Distributed Slurm cluster
