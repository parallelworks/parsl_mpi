#! /bin/bash
#===============================
# Install Ferret
#
# Based on the instructions at:
# https://ferret.pmel.noaa.gov/Ferret/downloads/ferret-installation-and-update-guide
#===============================

# Select a place to install Ferret and make tree
export FER_BASE=${HOME}/ferret_install
export FER_DIR=${FER_BASE}/ferret
export FER_DSETS=${FER_DIR}/fer_dsets
mkdir -p $FER_DSETS

# Get src tarball
cd $FER_DIR
wget https://github.com/NOAA-PMEL/PyFerret/releases/download/v7.6.3/PyFerret-7.6.3-RHEL7-Python3.6.tar.gz
tar -xzf PyFerret-7.6.3-RHEL7-Python3.6.tar.gz

# Make a datasets dir
cd $FER_DSETS
wget https://github.com/NOAA-PMEL/FerretDatasets/archive/refs/tags/v7.6.tar.gz
tar -xzf v7.6.tar.gz

# Start Finstall
cd $FER_DIR
echo "Done copying/unpacking files. Start Finstall. Use this info with option 2:"
echo "FER_DIR: ${FER_DIR}/pyferret-latest-local"
echo "FER_DSETS: ${FER_DIR}/fer_dsets/FerretDatasets-7.6"
echo "Directory to install ferret_paths: ${FER_BASE}"
./pyferret-latest-local/bin/Finstall

