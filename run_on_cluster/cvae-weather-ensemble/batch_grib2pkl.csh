#!/bin/tcsh -f
#======================
# Batch convert a bunch
# of grib2 files to .pkl
#
# Need to do it this way
# b/c this Docker container
# has the only Conda env
# I managed to get to install
# pynio or cfgrib.
#======================

# First, start the Docker container:
# sudo docker run -it -v /home/sfgary/sbir-learnerworks-doc/NOAA_JTTI:/noaa stefanfgary/socks /bin/bash

# Then, need to install the following packages in pyferret env:
# conda install -y -c conda-forge tensorflow
# conda install -y -c conda-forge scikit-learn
# conda install -y -c conda-forge cartopy
# conda install -y -c conda-forge xarray
# conda install -y -c conda-forge pynio
# conda install -y -c conda-forge dask


# Inside the container, run
# the following:

foreach file ( pres_sfc_20190101* )
    echo Working on $file
    set bn = `basename $file`
    set pn = ${bn}.pkl
    python -c "import xarray as xr; import pickle; slp=xr.open_mfdataset('$file', engine='cfgrib'); f = open('$pn', 'w'); pickle.dump(slp, f)"
end
