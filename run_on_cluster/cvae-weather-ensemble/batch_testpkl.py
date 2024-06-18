#!/bin/tcsh -f
#======================
# Batch test a bunch
# of pkl files before
# starting big ML run.
#======================

# First, start the Docker container:
# sudo docker run -it -v /home/sfgary/sbir-learnerworks-doc/NOAA_JTTI:/noaa tensorflow/tensorflow /bin/bash

import numpy as np
import pickle
import glob

file_list = glob.glob('pres_msl_*.nc.pkl')
for file in file_list:
    print('Working on '+file)

    with open(file, 'rb') as handle:
        test = pickle.load(handle)
        print(np.shape(test))
        print('Num NaN: '+str(np.sum(np.isnan(test))))
        print('Mean: '+str(np.mean(test)))
        print('Std: '+str(np.std(test)))
        print('Min: '+str(np.min(test)))
        print('Max: '+str(np.max(test)))
