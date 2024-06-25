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

# Needs CDO:
# sudo apt-get install cdo

foreach file ( ./gefs_data/pres_*.grib2 )
    echo Working on $file
    set bn = `basename $file .grib2`
    cdo -f nc copy $file ./gefs_data/${bn}.nc
end
