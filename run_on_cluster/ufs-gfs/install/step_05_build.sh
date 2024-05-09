#! /bin/bash
#========================
# Build it
#========================

# Change to $HOME just in case (don't
# want to put build repo in other git
# repo.)
cd $HOME

# Get UFS global workflow
git clone --recursive -b wei-epic-gcp https://github.com/NOAA-EPIC/global-workflow-cloud

