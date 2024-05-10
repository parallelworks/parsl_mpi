#! /bin/bash
#===============================
# Download a copy of the data
# we need to run the weather model
#
# Instructions:
# 
#===============================

# Select regression test case (tests/tests/control_p8)
# GENERALIZE?

# Where should I put this data?!
ufs_input_data=${HOME}/ufs-data
mkdir -p ${ufs_input_data}
cd ${ufs_input_data}

wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/atmf000.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/atmf021.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/atmf024.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSFLX.GrbF00
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSFLX.GrbF21
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSFLX.GrbF24
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSPRS.GrbF00
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSPRS.GrbF21
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/GFSPRS.GrbF24
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/sfcf000.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/sfcf021.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/sfcf024.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.coupler.res
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile1.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile2.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile3.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile4.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile5.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_core.res.tile6.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile1.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile2.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile3.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile4.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile5.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_srf_wnd.res.tile6.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile1.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile2.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile3.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile4.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile5.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.fv_tracer.res.tile6.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile1.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile2.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile3.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile4.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile5.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.phy_data.tile6.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile1.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile2.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile3.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile4.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile5.nc
wget https://noaa-ufs-regtests-pds.s3.amazonaws.com/develop-20230517/INTEL/control_p8/RESTART/20210323.060000.sfc_data.tile6.nc
