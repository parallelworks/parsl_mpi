#!/bin/tcsh -f

#======================
# Batch convert a bunch
# of grib2 files to .nc
#
# Needs CDO
#======================

foreach file ( ./gefs_data/pres_*.grib2 )
    echo Working on $file
    set bn = `basename $file .grib2`
    cdo -f nc copy $file ./gefs_data/converted/${bn}.nc
end
