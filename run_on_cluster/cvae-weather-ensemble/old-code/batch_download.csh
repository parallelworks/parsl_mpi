#!/bin/tcsh -f
#========================
# Download a year of GEFS
# output.
#=======================

# Choose years
#set year_list = ( 2018 2019 )
set year_list = ( 2012 2013 2014 2015 2016 2017 )

# Choose all months.
set month_list = ( 01 02 03 04 05 06 07 08 09 10 11 12 )

# Forecasts are 10 days long, so this provides converage of whole year.
set day_list = ( 01 10 20 )

foreach year ( $year_list )
    foreach month ( $month_list )
	foreach day ( $day_list )
	    wget https://noaa-gefs-retrospective.s3.amazonaws.com/GEFSv12/reforecast/${year}/${year}${month}${day}00/c00/Days%3A1-10/pres_msl_${year}${month}${day}00_c00.grib2
	    mv pres_msl_${year}${month}${day}00_c00.grib2 ./gefs_data
	end
    end
end
