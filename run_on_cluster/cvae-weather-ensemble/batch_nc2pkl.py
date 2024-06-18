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


# Inside the container, start conda:
# source /opt/conda/etc/profile.d/conda.sh
# activate pyferret

import pyferret as pf
import numpy as np
import pickle
import glob
import os

file_list = glob.glob('pres_msl_*.nc')
for file in file_list:
    print('Working on '+file)
    pf.start(quiet=True)
    (ev, em) = pf.run('set memory /size=80000')
    (ev, em) = pf.run('use '+file)
    data_dict = pf.getdata('msl',False)
    # Need to add channel dim for TF
    # Need to flip back latitude b/c ferret flips it on load
    # Need to swap time and lon axes -> time becomes batch_size,
    #    going from FORTRAN (ferret) indexing to C (python) indexing
    data=np.expand_dims(
        np.flip(
            np.swapaxes(
	        np.squeeze(data_dict['data']),
		0,2),
	    1),
	-1)/120000
	    
    #data_f16 = data.astype('float16')
    print(np.shape(data))
    print('Num NaN: '+str(np.sum(np.isnan(data))))
    print('Mean: '+str(np.mean(data)))
    print('Std: '+str(np.std(data)))

    # Lots of possible issues with using float16 instead of float32.
    # -> cannot take std of data with numpy
    # -> matplotlib not happy
    #print(np.shape(data_f16))
    #print('Num NaN: '+str(np.sum(np.isnan(data_f16))))
    #print('Mean: '+str(np.mean(data_f16)))
    #print('Std: '+str(np.std(data_f16)))

    # Write file
    with open(file+'.pkl', 'wb') as handle:
        pickle.dump(data, handle, protocol = pickle.HIGHEST_PROTOCOL)

    os.system("rm -f "+file)
	
    run_test = False
    if run_test:
        # Test read
        with open(file+'.pkl', 'rb') as handle:
            test = pickle.load(handle)
        print(np.shape(test))
        print('Num NaN: '+str(np.sum(np.isnan(test))))
        print('Mean: '+str(np.mean(test)))
        print('Std: '+str(np.std(test)))
