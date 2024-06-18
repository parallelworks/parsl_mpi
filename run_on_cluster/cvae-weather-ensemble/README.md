# VM setup
1. Testing whether I can use a lower cost VM (n1-standard-4) to `conda install` and pre-download data and save data on image and then reboot image as a higher cost (a2-highgpu-1g) for the actual training.  This seems to work BUT may require reinstalling Linux headers when going from low->high cost and then rebooting the VM, e.g.:
```bash
# Booted as a2-highgpu-1g after run as n1-standard-4 -> error message.
sudo apt-get install linux-headers-4.19.0-18-cloud-amd64
reboot
```
See `/var/log/apt/history.log` for history of install requests (includes the tcsh install in #4 below).  Also, note that while it is possible to switch between n1-standards and a1-highgpu, you **cannot** switch between e1 class machines and a1 machines.

2. Testing whether I can use pygrib as a direct load from grib -> YES, but need to manually add time axis and concatenate time steps within files in addition to concatenating time steps between files.  See load_many_grib in main_cvae.py.

3. Using the c1-deeplearning-tf-2-5-cu110-v20210714-debian-10 image as a starting point.  It has conda and I will attempt to install default pygrib and parsl into the base conda environment.  It appears that all the other key packages are already installed (numpy, pandas, matplotlib, json, os, scikit-learn, tensorflow, pickle, glob).

4. Actual steps executed on an n1-standard-4:
```bash
conda install -c conda-forge pygrib  # Could not solve env before package download but installed anyway.
conda install -c conda-forge parsl   # Installed without issue (downgrading sqlalchemy)
sudo apt-get install tcsh            # Used for some of the batch scripts in this dir, could be bypassed.
```

5. Testing data loading:
```python
import numpy as np
import pygrib
file_name = "./gefs_data/pres_msl_2019110100_c00.grib2"
file_data = pygrib.open(file_name)
msl = file_data.select(name='Mean sea level pressure')
data = msl[0].values
np.shape(data)
(721, 1440)
```

6. Testing the use of smaller data types.  Please see [this blog](https://towardsdatascience.com/memory-efficient-data-science-types-53423d48ba1d) for a great intro to which data types are supported and how.  In a nutshell, float16 is dangerous to use because it has inconsistent support.  Float64 is the default numpy type, float32 should work easily with `data.astype(np.float32)`. The most commonly supported ints are int8 and int32, but there is no mention of the reliability of int16, which is what I want to use.

# Data sizes:

1. Each GEFS 2D field with 80 time steps (10 days at 3 hours) is 57MB in grib2
2. Converted to netcdf, the field with 80 time steps is 317MB
3. A whole year in NetCDF is 12 months x 3 fields/month * 317MB = 11GB
4. Converted to pkl, each file is 634MB x 36 = 22GB
5. We need to figure out a robust and efficient way to go from grib2 to load to memory.  Currently, this multistage approach is slow and takes up a lot of space.

# Pipeline summary:

1. wget to download from NOAA's S3 bucket
2. cdo to convert to nc (`apt-get install cdo`)
3. pyferret to load as numpy array (`conda install -y -c conda-forge pyferret`)
4. save as pkl for use outside of pyferret container b/c pyferret will not install in Conda (like pynio and cfgrib)

This means ignore `batch_grib2pkl.csh` because pynio/cfgrib don't work reliably.

# Tensorflow:

1. docker pull tensorflow/tensorflow
2. Run this container, e.g. sudo docker run -it -v/home/sfgary/sbir-learnerworks-doc/NOAA_JTTI:/tmp/noaa tensorflow:tensorflow /bin/bash
3. pip install pandas
4. pip install scikit-learn
5. pip install matplotlib

# Grids

Since we have broken away from grib/netcdf, we need to explicitly
bring back the grid information.  Here, I used ncdump -h on the lon
and lat variables in .nc files, manually removed the header, and
then used the following text pipeline to make into a column vector
in a text file:

cat lon.txt | tr -d '}' | tr -d ';' | tr -d '\n' | tr -d ' ' | tr ',' '\n' > lon.x
cat lat.txt | tr -d '}' | tr -d ';' | tr -d '\n' | tr -d ' ' | tr ',' '\n' > lat.y

# Training the ML model

For two years of data (36 files each year, each file has 80 3h time steps = 10 days)
(Used 2018 and 2019)

Input summary:
(5760, 721, 1440, 1)
Mean: 0.9185315259371455
Std:  0.012157332330270077
Testing shape
(1440, 721, 1440, 1)
Training shape
(3240, 721, 1440, 1)
Validaiton shape
(1080, 721, 1440, 1)

Takes about 10 mins per epoch, uses ~128GB RAM, linear scaling wrt batch size seems
confirmed wrt previous runs. Running on 32CPU, all utilized but at around 50%.

Training time:
Start: 2021-11-14 15:16:14
End: 

# Using the ML model

The model weights are in ./gefs/vae.data-00000-of-000001. The Python/Tensorflow
code that defines the model needs to be loaded first and then the weights are
loaded.