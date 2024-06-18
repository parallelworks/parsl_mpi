import xarray as xr
import pickle
import glob

file_list = glob.glob('pres_sfc_20190101*.grib2')
for file in file_list:
    print('Working on '+file)
    data=xr.open_mfdataset(file, engine='cfgrib')
    with open(file+'.pkl', 'wb') as handle:
        pickle.dump(data, handle, protocol = pickle.HIGHEST_PROTOCOL)


