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
cd ..
rm -rf slurm-cluster
```


## Distributed Slurm cluster
