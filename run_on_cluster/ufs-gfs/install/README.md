# Installation of UFS on cloud clusters

Weather models are perfect examples of complex software 
stacks due to the many dependencies that underpin them.
Here, we step through the process of setting up the:
1. system level dependencies (OS-level package installs),
2. package manager depenendencies (i.e. Spack and Conda), and
3. final application build

## Step 1: System-level dependencies

### Rocky8

See `step_01_sys_dep_Rocky8.sh` for system install based on these 
[instructions](https://spack-stack.readthedocs.io/en/latest/NewSiteConfigs.html#prerequisites-red-hat-centos-8-one-off). 
Deviations from these instructions include:
1. not running `sudo yum -y update` since cloud images' packages 
   are carefully tuned and it will take long time.


### Centos7

## Step 2: Package manager dependencies

## Step 3: Final build


