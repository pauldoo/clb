# Containerised Linux Build (CLB)

Build Linux kernels and boot them in Fedora bootc VMs. Cache a baseline build so that incremental builds are fast(er).

Prerequisites:
* podman
* bcvk
* Linux kernel source code checked out into `./linux`.

Usage:
```
just run <base commit> <test commit>
```

`base commit`: Try to keep this consistent over multiple runs. On first run a build is performed using this commit, and the build artifacts are stored as an image. It could be the base commit for your branch.

`test commit`: The commit to actually boot. Can be the same as the base commit. The build will start from the image of the base commit (which is prebuilt), update to the new commit, and do an incremental build.

As you develop your linux kernel change and make new commits to your branch or amend them, rerun `just run` and change only the test commit argument. The builds will be mostly incremental since they start from the cached build of the base commit. After making a small commit to the linux source tree, on my 2019 laptop it takes ~3 minutes for `just run` to perform the incremental build, create a new bootc image with the kernel installed, boot it, and show the logged-in terminal.

Each test produces a new bootable container image. These are independent and can be booted simultaneously or retained to revisit later.