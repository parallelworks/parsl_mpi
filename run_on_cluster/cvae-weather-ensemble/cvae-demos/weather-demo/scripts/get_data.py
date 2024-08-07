import os

# download
def download_file(year, month, day, ensemble, data_predir):
    if f'pres_msl_{year}{month}{day}00_{ensemble}.grib2' not in os.listdir(data_predir):
        os.system(f'wget -q -P {data_predir} https://noaa-gefs-retrospective.s3.amazonaws.com/GEFSv12/reforecast/{year}/{year}{month}{day}00/{ensemble}/Days%3A1-10/pres_msl_{year}{month}{day}00_{ensemble}.grib2')

# convert
def convert_file(year, month, day, ensemble, data_dir):
    if f'pres_msl_{year}{month}{day}00_{ensemble}.grib2' in os.listdir('./gefs_data') and f'pres_msl_{year}{month}{day}00_{ensemble}.nc' not in os.listdir(data_dir):
        os.system(f'cdo -f nc copy ./gefs_data/pres_msl_{year}{month}{day}00_{ensemble}.grib2 {data_dir}pres_msl_{year}{month}{day}00_{ensemble}.nc')

# subset
def subset_file(data_file, data_dir):
    if '.nc' in data_file and f'{data_dir}subset_{data_file}' not in os.listdir(data_dir):
        os.system(f'ncks -v msl -d time,1,79,2 {data_dir}{data_file} -O {data_dir}subset_{data_file}')
    
# delete (all)
def remove_data(data_predir):
    os.system(f'find {data_predir} -type f -delete')