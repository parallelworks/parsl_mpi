#!/bin/bash

# Start Conda and select env (you will need to cross-check the paths and env name)

source ~/pw/.miniconda3c/etc/profile.d/conda.sh
conda activate cvae_env

# Run the git commands using input from the command line;
# $1 stores the first entry on the command line that launches
# the shell script and so on. Add as many as you need.

file_name=$1
commit_message="$2"

dvc add "$file_name"
git add .gitignore "${file_name}.dvc"

dvc push
git commit -m "$commit_message"
git push