#!/bin/bash

# Run the git commands using input from the command line;
# $1 stores the first entry on the command line that launches
# the shell script and so on. Add as many as you need.

file_name=$1
commit_message="$2"
dvc_dir="$3"
env_name="$4"

# Start Conda and select env (you will need to cross-check the paths and env name)

source ~/pw/.miniconda3c/etc/profile.d/conda.sh
conda activate "$env_name"

cd "$dvc_dir"

dvc add "$file_name"
git add .gitignore 
git add "${file_name}.dvc"

dvc push
git commit -m "$commit_message"
git push