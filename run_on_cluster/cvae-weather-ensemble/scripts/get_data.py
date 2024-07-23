import os

data_pdir = "./gefs_data"
data_dir = "./gefs_data/converted/"

# data download
def download_file(year, month, day, ensemble, data_pdir):
    if f'pres_msl_{year}{month}{day}00_{ensemble}.grib2' not in os.listdir(data_pdir):
        !wget -q -P {data_prefix} https://noaa-gefs-retrospective.s3.amazonaws.com/GEFSv12/reforecast/{year}/{year}{month}{day}00/{ensemble}/Days%3A1-10/pres_msl_{year}{month}{day}00_{ensemble}.grib2

# data conversion
def convert_file(year, month, day, ensemble, data_pdir):
    if f'pres_msl_{year}{month}{day}00_{ensemble}.grib2' in os.listdir(data_pdir):
        !cdo -f nc copy ./gefs_data/pres_msl_{year}{month}{day}00_{ensemble}.grib2 ./gefs_data/converted/pres_msl_{year}{month}{day}00_{ensemble}.nc
        
# data deletion
def remove_data():
    !find {data_pdir} -type f -delete