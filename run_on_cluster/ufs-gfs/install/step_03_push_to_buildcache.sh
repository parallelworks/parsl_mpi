#! /bin/bash
#=============================
# Push all packages here to
# the buildcache.
#=============================

# You need to activate spack first...

for ii in $(spack find --format "yyy {version} /{hash}" |
	    grep -v -E "^(develop^master)" |
	    grep "yyy" |
	    cut -f3 -d" ")
do
  echo Working on $ii
  spack buildcache create -af --only=package --unsigned ufs-cache $ii
done

