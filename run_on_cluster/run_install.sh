#!/bin/bash
#========================================
# Automate/document the install process
#========================================

# The separate installers used here are copied
# from Chris Harrop's https://github.com/NOAA-GSL/ExascaleWorkflowSandbox

echo "======================================="
echo Installing Spack...
echo "======================================="
./install_spack.sh /home/sfgary/flux v0.20.0

echo "======================================="
echo Installing base env in Spack...
echo "======================================="
./install_base.sh

echo "======================================="
echo "Installing Flux in Spack...
echo "======================================="
./install_flux.sh


