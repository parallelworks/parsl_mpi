#! /bin/bash
#=====================================
# Install spack-stack for use with UFS
#
# Run this script in a gcc-toolset-11
# enabled bash shell to access gcc11,
# i.e.:
#
# scl enable gcc-toolset-11 bash
# ./step_02_spack-stack.sh
#
#=====================================

# Download Spack, start it, and add the buildcache
# mirror to Spack. Use the default location for spack-stack
# for now.
spack_dir=/contrib/spack-stack/spack-stack-1.6.0
mkdir -p $spack_dir
cd $spack_dir
git clone -c feature.manyFiles=true https://github.com/spack/spack.git
. ${PWD}/spack/share/spack/setup-env.sh
spack mirror add aws-mirror s3://$BUCKET_NAME
spack compiler find
spack buildcache list


