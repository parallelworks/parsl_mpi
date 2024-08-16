# CVAE Digits Example Demo
This demo is dervied [Francois Chollet's](https://keras.io/examples/generative/vae/) Variational AutoEncoder example, modified for online learning. In particular, some goals are:

* Test computational performance scaling (CPUs, GPUs)
* Test model performance while saving and fitting again (in particular, adding more data instead of having all the data available at once).
* Integrations with DVC

## Environment Set Up
To get started with the CVAE Digit Model, follow the instructions below to set up your environment.

### Create Environment:
```
source ~/pw/.miniconda3c/etc/profile.d/conda.sh
conda create --name <NAME> python=3.9
conda activate <NAME>
```

### Install Packages:
The following packages need to be installed on top of a typical base Conda env. Install the packages in the following order so the environment solves correctly:
```
conda install -y -c conda-forge tensorflow
conda install -y -c conda-forge matplotlib
conda install -y -c conda-forge pandas
conda install -y -c conda-forge dvc 

pip install mlflow
```

### Connect Notebook to Environment:
```
conda install -y ipykernel
conda install -y requests
conda install -y -c anaconda jinja2
python -m ipykernel install --user --name=<NAME> --display-name "Python (<NAME>)"
```

### Alternative Set Up:

1. Run `conda env update --file digits_env.yaml --name <NAME>` to install the conda environment with all the needed dependencies 
2. Run `source ~/pw/.miniconda3c/etc/profile.d/conda.sh` to initiate conda 
3. Run `conda activate <NAME>` to activate the environment you installed
4. Run `python -m ipykernel install --user --name=<NAME> --display-name "Python (<NAME>)"` to connect the environment to the notebook

## Needed Specifications

**Storage:** Mounted storage is required for dvc to run properly.\
**GitHub:** A separate git repo that can be SSH into is also needed for dvc to run properly. SSH connection must be established on the terminal.
