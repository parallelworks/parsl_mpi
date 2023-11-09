#!/bin/bash
#===============
# Grab a preexisting
# OpenFOAM dataset for
# fancy visualization
# with Paraview
#===============

echo 'Grabbing existing OpenFOAM dataset...'

mkdir -p $HOME/openfoam_vis
cp /contrib/sfgary/cyclone.out.tar.gz $HOME/openfoam_vis/

cd $HOME/openfoam_vis
tar -xzf cyclone.out.tar.gz

echo 'Done! Navigate to $HOME/openfoam_vis/cyclone'
echo 'and then type: paraview out.foam'

