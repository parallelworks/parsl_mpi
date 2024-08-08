#!/bin/bash

# Start Conda and select env (you will need to cross-check the paths and env name)

source ~/pw/.miniconda3c/etc/profile.d/conda.sh
conda activate cvae_env

# Run the git commands using input from the command line;
# $1 stores the first entry on the command line that launches
# the shell script and so on. Add as many as you need.

file_name=$1
commit_message="$2"

cd digits_dvc && dvc add "$file_name"
cd digits_dvc && git add .gitignore 
cd digits_dvc && git add "${file_name}.dvc"

cd digits_dvc && dvc push
cd digits_dvc && git commit -m "$commit_message"
cd digits_dvc && git push