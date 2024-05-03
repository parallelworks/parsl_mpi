#! /bin/bash
#=============================
# Push all packages here to
# the buildcache.
#=============================

# You need to activate spack first
# and add the mirror. The local name
# for the mirror ufs-cache.
mirror_name="ufs-cache"

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

