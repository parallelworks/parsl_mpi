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

# the following:

foreach file ( pres_sfc_20190101*.nc )
    echo Working on $file
    set bn = `basename $file .nc`
    set pn = ${bn}.pkl
    python -c "import pyferret as pf; import pickle; import numpy as np; pf.start(quiet=True); (ev, em) = pf.run('set memory /size=80000'); (ev, em) = pf.run('use $file'); slp_dict = pf.getdata('sp',False); slp=np.asarray(np.swapaxes(np.squeeze(slp_dict['data']),0,2)); print('Num NaN: '+str(np.sum(np.isnan(slp)))); f = open('$pn', 'wb'); pickle.dump(slp, f); f.close();"
end
