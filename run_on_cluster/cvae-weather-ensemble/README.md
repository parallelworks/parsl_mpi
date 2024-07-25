# CVAE Weather Ensemble Model

This is the CVAE Weather Ensemble Model repository. The model leverages the power of Conditional Variational Autoencoders (CVAE) to provide an ensemble training system for weather predictions while also answering the big data problem. Its capability for online training allows for continuous learning from new data streams without compromising performance. That is, data used to train the model is processed in small batches, the model being retrained with each new batch. 

## Key Features

* **Conditional Variational Autoencoder (CVAE):** Utilizes CVAE with Conv2d networks to model complex dependencies in weather data, enabling accurate probabilistic forecasts.
* **Online Training:** Implements a dynamic training approach that can adapt to real-time incoming data, ensuring up-to-date forecasts.
* **Data Version Control (DVC):** Manages datasets and model versions effectively with DVC, facilitating reproducibility and collaboration.

## Getting Started

To get started with the CVAE Weather Ensemble Model, follow the instructions below to set up your environment.

### 1. Conda env setup
*The following is the list steps needed to be taken in order to set up a correct conda environment for running this notebook.*

**Create Environment:**
```bash
source ~/pw/.miniconda3c/etc/profile.d/conda.sh
conda create --name <NAME> python=3.9
conda activate <NAME>
```

**Install Pacakages:** 

The following packages need to be installed on top of a typical base Conda env. Install the packages in the following order so the environment solves correctly:
```bash
conda install -y -c conda-forge tensorflow
conda install -y -c conda-forge netCDF4          # For reading nc files
conda install -y -c conda-forge cartopy          # For making maps
conda install -y -c conda-forge matplotlib
conda install -y -c conda-forge pandas
conda install -y -c conda-forge scikit-learn
conda install -y -c conda-forge papermill        # For running online training
conda install -y -c conda-forge dvc              # For dvc
conda install -y -c conda-forge nco
conda install -y -c conda-forge cdo              # For converting grib to nc
```
**Connect Notebook to Environment:**
```bash
conda install -y ipykernel
conda install -y requests
conda install -y -c anaconda jinja2
python -m ipykernel install --user --name=<NAME> --display-name "Python (<NAME>)"
```

*`conda env update --file cvae_env.yaml --name <NAME>` can also be used to recreate the working conda environment used to build this model. After this executes run `source ~/pw/.miniconda3c/etc/profile.d/conda.sh`, `conda activate <NAME>`, and then `python -m ipykernel install --user --name=<NAME> --display-name "Python (<NAME>)"`* 

### 2. Open the `cvae_runner_and_example.ipynb`, `cvae_training.ipynb`, and `cvae_log.ipynb` notebooks

When opening the notbooks make sure to set each of their kernel to the one just created. Save the notebook after this is done. You can also close out of the `log` and `training` notebooks if wanted. Note: in order to see an updated log when running the online trainging, the `log` notebook must be closed and opened again throughout the session.

### 3. Continue to `cvae_runner_and_example.ipynb` and follow the instructions in the notebook

## Needed Specifications
**GPU & Memory:** The program requires at least 32 G of RAM.\
**Storage:** Mounted stoarge is required for dvc to run properly.\
**GitHub:** A git repo that can be SSH into is also needed for dvc to run properly. SSH connection must be established on the terminal.

##

*This model is based on an [example](https://keras.io/examples/generative/vae/) from Keras.io by fchollet ([GitHub](https://github.com/keras-team/keras-io/blob/master/examples/generative/vae.py))*
