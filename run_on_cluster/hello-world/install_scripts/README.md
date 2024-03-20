# Notes on setting up a Spack build cache

## Resources

[Mirror tutorial](https://spack-tutorial.readthedocs.io/en/ecp21/tutorial_binary_cache.html)
[Build cache docs](https://spack.readthedocs.io/en/latest/binary_caches.html)

## Nomenclature

A build cache is a store of binaries compiled as part of the `spack install` process. 
Spack mirrors are **augmented** with build caches.  That is, first a Spack mirror is 
set up, and then the build artefacts are added to the mirror. The mirror can be used
to store source code as well as build artefacts.  Mirrors with source only are often 
used for air-gapped systems and build cache augmented mirrors are great for teams 
sharing the same software or quickly redeploying built software on ephemeral 
instances.

## End-to-end example of a cloud bucket build caches

### Install system dependencies
```
# Spack needs this to use AWS buckets
pip install boto3

# Spack needs this to use GCP buckets
# NOTE: WORKING HERE - THERE IS SOME KIND OF SPACK
# ERROR WITH AUTHENTICATING TO GOOGLE USING ENV VAR CREDS
# This error only comes up at the spack install stage
# because it is only at that point that Spack attempts to
# read the bucket to find if there are any cached build
# artefacts for it to use. An alternative is to use 
# gcsfuse to mount the bucket to the filesystem and then
# tell Spack to just treat the bucket mount point as 
# a mirror. gcsfuse docs here:
# https://cloud.google.com/storage/docs/gcsfuse-quickstart-mount-bucket
pip install google
pip install google-cloud-storage
```

### Install and set up Spack
```
# Download
git clone https://github.com/spack/spack ~/spack

# Select Spack version (look up most recent release) 
cd ~/spack
git checkout v0.21.2

# Activate Spack
source ~/spack/share/spack/setup-env.sh
```

### Set up a gpg key to sign build artefacts/packages
```
# Spack saves this key in ${SPACK_ROOT}/opt/spack/gpg/secring.gpg and pubring.gpg
spack gpg create "My Name" "<my.email@my.domain.com>

# Copy the PUBLIC key to the mirror. Bucket creds
# already set in environment variables.
aws s3 cp /home/sfgary/spack/opt/spack/gpg/pubring.gpg s3://$AWS_BUCKET_NAME
gcloud storage cp /home/sfgary/spack/opt/spack/gpg/pubring.gpg gs://$GCP_BUCKET_NAME
```

### Set up the Spack mirror
```
# Which spack mirrors are already present? There is 1 default
spack mirror list

# Add a mirror on a bucket. Note that bucket 
# credentials are already entered as environment vars.
# spack mirror list shows the new mirrors.
spack mirror add gcp-mirror gs://$GCP_BUCKET_NAME
spack mirror add aws-mirror s3://$AWS_BUCKET_NAME
spack mirror add local-mirror /home/sfgary/mirror
```

### Locally install some dependencies with Spack
```
# Install a relatively lightweight package. This package
# will also pull and build gmake.
spack install zlib

# Check that the packages are installed
spack find
```

### Push built results to the mirror

Use the spack find command to list all the installed packages. Also, skip
any external packages. The final cut command isolates the hash for each 
package. Any of the configured mirror names should work in the 
<mirror-name> field.
```
for ii in $(spack find --format "yyy {version} /{hash}" |
	    grep -v -E "^(develop^master)" |
	    grep "yyy" |
	    cut -f3 -d" ")
do
  spack buildcache create -af --only=package <mirror-name> $ii
done
```
Note that Spack is smart enough to check whether that exact package/hash 
exists in the mirror and will only overwrite it if using --force.

### Index the buildcache
This step will allow users to list packages available in a buildcache
and search for packages. This is run each time a change is made to the
buildcache.
```
spack buildcache update-index <mirror-name>
```

### Grab those results on another cluster
On a different cluster, install boto3 (for AWS, other steps for GCP and Azure) 
and Spack as above and add the cloud bucket creds to your environment variables. 
Also, add the mirror as above, e.g.
```
spack mirror add <mirror-name> <mirror-path-or-URL>
```
The `mirror-name` above is a LOCAL choice whereas the `mirror-path-or-URL` is
the "universal" handle on the mirror (i.e. a bucket or location on the
file system). If you just want to trust anything on the mirror, you can
trust all the keys there:
```
# I don't think this did anything? More work required here
# to develop a streamlined/generalized key approach
spack buildcache keys --install --trust --force

# Instead, I copied the pubring.gpg public key copied onto the bucket
# to my local machine and this seemed to work:
aws s3 cp s3://$AWS_BUCKET_NAME/pubring.gpg /home/sfgary/spack/opt/spack/gpg/pubring.gpg 

# Install compiled binaries direct from the mirror (lazily checks the mirror):
spack install zlib
```

