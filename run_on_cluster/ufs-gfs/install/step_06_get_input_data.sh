#! /bin/bash
#===============================
# Download a copy of the data
# we need to run the weather model
#
# Instructions:
# Overview of data download instructions:
# https://ufs-weather-model.readthedocs.io/en/develop/BuildingAndRunning.html#get-data 
#
# Specific preface to the AWS bucket 
# for the regression test data including
# examples for how to grab data w/o
# credentials.
# https://registry.opendata.aws/noaa-ufs-regtests/
#
#===============================

# Select regression test case (tests/tests/control_p8)
# Note that some older regression test cases have
# the compiler as part of the path and others have
# the compiler as part of the regression test name!
# Double check the pathname of the baseline you are
# comparing to with aws s3 ls --no-sign-request s3://...
#=======================================
baseline_branch=develop-20240426
test_case=control_c48_
compiler=intel

# Where should I put this data?!
ufs_input_data=${HOME}/ufs-data
mkdir -p ${ufs_input_data}
cd ${ufs_input_data}

# Download the data
aws s3 sync --no-sign-request s3://noaa-ufs-regtests-pds/${baseline_branch}/${test_case}${compiler} ./

