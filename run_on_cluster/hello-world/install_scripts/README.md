# Notes on `hello-world` case setup and testing

The general approach here has been tested on both Centos7 
and Rocky8 images.

## Testing MPI on clusters

### Cluster state

`sinfo` is a great command to use to query the cluster state.
Output might look like this:
```
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST 
compute*     up   infinite      2  idle% sfgary-gg-00002-1-[0003-0004] 
compute*     up   infinite      8  idle~ sfgary-gg-00002-1-[0001-0002,0005-0010] 
```
Note that here, two nodes are powering down and 8 are powered down.
(The powered down nodes are actually non-existant to reduce costs.)
When nodes are allocated jobs, `idle` changes to `alloc`.
Node statuses (i.e. `~` means powered down, `%` means powering down)
are defined more fully in the [SLURM documentation](https://slurm.schedmd.com/sinfo.html#SECTION_NODE-STATE-CODES).

### OpenMPI + Tau + Flux example

With devtools-7 (gcc 7.3.1), I can install tau directly on the system. 
I can also use that compiler to build OpenMPI outside of Spack. So, use
first built OpenMPI outside of Spack, add it as an external package,
and finally install Tau with Spack with the following:
```
spack install tau +mpi +papi +pthreads ^openmpi
``` 
and Tau does finish installing. To get Tau profiling to work, I need to 
first jump into an allocation and then use `mpiexec`. For example,
```
# Load tau (two different taus are installed, one doesn't have mpi by default)
spack load tau+mpi+papi+pthreads 

# Get allocation
salloc -N 2 -n 4 -p small

# Run with mpiexec
mpiexec -np 4 tau_exec ~/a.out

#OR, you can use sbatch:
sbatch -N 2 -n 4 -p small --wrap "mpiexec -np 4 tau_exec ~/a.out"
```
So, next, we want to test Tau profiling with a Flux-launched MPI job.
Here is an example:
```
#Start a Flux instance
srun -N2 -n4 --pty -p small flux start

# The above wasn't happy because devtools-7 is not installed on all nodes.  Let's see to what extent we need that...
# Simple test of flux alloc did not work...
# Test resource list
[~]$ flux resource list
     STATE NNODES   NCORES    NGPUS NODELIST
      free      4        4        0 sfgary-cloud2-00065-2-[0001,0001-0002,0002]
 allocated      0        0        0 
      down      0        0        0 

# Flux thinks I have too many nodes... but at least it can count all the CPUS
[~]$ flux exec flux getattr rank
0
1
2
3

# So now, let's send a job... Flux run works!!!
[~]$ flux run -n4 --label-io hostname
1: sfgary-cloud2-00065-2-0001
2: sfgary-cloud2-00065-2-0002
3: sfgary-cloud2-00065-2-0002
0: sfgary-cloud2-00065-2-0001

[~]$ flux run -n 4 ~/a.out
Hello world from processor sfgary-cloud2-00065-2-0001, rank 0 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0002, rank 2 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0002, rank 3 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0001, rank 1 out of 4 processors

[~]$ ls
a.out  ompi  parsl_flux  parsl_mpi  weather-cluster-demo

[~]$ flux run -n 4 tau_exec -io ~/a.out
Hello world from processor sfgary-cloud2-00065-2-0002, rank 3 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0001, rank 1 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0002, rank 2 out of 4 processors
Hello world from processor sfgary-cloud2-00065-2-0001, rank 0 out of 4 processors

[~]$ ls
a.out  parsl_flux  profile.0.0.0  profile.1.0.0  profile.2.0.0  profile.3.0.0  weather-cluster-demo
ompi   parsl_mpi   profile.0.0.1  profile.1.0.1  profile.2.0.1  profile.3.0.1
```

## Setting up a Spack build cache

### Resources

[Mirror tutorial](https://spack-tutorial.readthedocs.io/en/ecp21/tutorial_binary_cache.html)
[Build cache docs](https://spack.readthedocs.io/en/latest/binary_caches.html)

### Nomenclature

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

