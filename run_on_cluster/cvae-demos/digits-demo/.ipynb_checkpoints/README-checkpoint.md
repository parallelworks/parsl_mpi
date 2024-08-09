# CVAE Digits Example Demo
This notebook is dervied [Francois Chollet's](https://keras.io/examples/generative/vae/) Variational AutoEncoder example, modified for online learning. In particular, some goals are:

* test computational performance scaling (CPUs, GPUs)
* test model performance while saving and fitting again (in particular, adding more data instead of having all the data available at once).
* integrations with DVC

## Environment Set Up
To get started with the CVAE Digit Model, follow the instructions below to set up your environment.

1. Run `conda env update --file cvae_env.yaml --name <NAME>` to install the conda environment with all the needed dependencies 
2. Run `source ~/pw/.miniconda3c/etc/profile.d/conda.sh` to initiate conda 
3. Run `conda activate <NAME>` to activate the environment you installed
4. Run `python -m ipykernel install --user --name=<NAME> --display-name "Python (<NAME>)"` to connect the environment to the notebook
4. Install `pip install mlflow` to get mlflow on the environment
