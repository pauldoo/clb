# Containerised Linux Build (CLB)

Container based workflow for building Linux kernels then booting them in Fedora bootable containers for testing.

Builds take place inside Fedora container images and build artifacts are retained there. Builds can be clean, or incremental using a previous build as a starting point (faster than a clean build).

Built kernels can be installed to a Fedora bootable container, and booted locally using bcvk. Because all builds and bootable containers are independent of the working tree it is possible to easily switch between builds while testing.

# Prerequisites

* podman
* bcvk
* Just
* Linux kernel source code checked out into `./linux`

# Usage

The commits you wish to test must be part of a _local_ branch of the Linux code you have checked out. This is because only your local branches are cloned into the containers.

Build a kernel from clean for the specified commit:
```
just clean_build <commit>
```

Build a kernel incrementally (set `base commit` to any previous build):
```
just incremental_build <base commit> <new commit>
```

After you have either type of build done, login to a bootable container running a kernel:
```
just run <commit>
```

## Suggested Workflow

Perform a clean build for the base of your work (`just clean_build`). As you iterate and make new commits, use incremental builds to build new test kernels (`just incremental_build`), and boot them for testing using `just run`.

Each test produces a new bootable container image. These are independent and can be booted simultaneously or retained to revisit later. 

## Example

Build 7.0-rc5:
```
just clean_build c369299895
```

Run it:
```
just run c369299895
```

Later, we build 7.0-rc6 as an incremental build:
```
just incremental_build c369299895 7aaa8047ea
```

Then run it:
```
just run 7aaa8047ea
```