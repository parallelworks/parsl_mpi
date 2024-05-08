#! /bin/bash
#=============================
# Push all packages here to
# the buildcache.
#=============================

echo DO NOT RUN THIS SCRIPT WITH A SPACK
echo ENVIRONMENT ALREADY SET!
echo "=========================================="
spack_install=${HOME}/spack/spack-stack
mirror_name="ufs-cache"
spack_env="ufs-weather-model.my-linux"
echo "spack install: ${spack_install}"
echo "mirror name:   ${mirror_name}"
echo "spack_env: ${spack_env}"

# This works in two steps:
# 1) grab the packages from the "base Spack" (in particular compilers)
# 2) grab the packages from the build environment.

#=====================================================
#Part 1: base Spack
source ${spack_install}/setup.sh

# This mirror has already been added
# in step 2.

for ii in $(spack find --format "yyy {version} /{hash}" |
	    grep -v -E "^(develop^master)" |
	    grep "yyy" |
	    cut -f3 -d" ")
do
  echo Working on $ii
  spack buildcache create -af --only=package --unsigned ${mirror_name} $ii
done

# After a push, you need to:
spack buildcache update-index ${mirror_name}

#===================================================
# Part 2: the build environment
cd ${spack_install}/envs/${spack_env}
spack env activate -p .

for ii in $(spack find --format "yyy {version} /{hash}" |
            grep -v -E "^(develop^master)" |
            grep "yyy" |
            cut -f3 -d" ")
do
  echo Working on $ii
  spack buildcache create -af --only=package --unsigned ${mirror_name} $ii
done

# After a push, you need to:
spack buildcache update-index ${mirror_name}

