# 6.19
#base_commit := "05f7e89ab9731565d8a62e3b5d1ec206485eeb0b"
# 2025-02-14: btrfs-devel/master
#base_commit := "44331bd6a610"
# 2025-02-16: btrfs-devel/misc-next
#base_commit := "f48d2006cea"


default:
    just --list

# Create base image used for kernel builds.
buildenv:
    podman image exists clb_buildenv || \
    podman build buildenv \
      --tag clb_buildenv \

# Image with linux git cloned - but no code checked out yet.
cloneenv: buildenv
    podman image exists clb_cloneenv || \
    podman build cloneenv \
      --tag clb_cloneenv \
      --security-opt label=disable \
      --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

# Image with linux commit checked out and configured. Not incremental.
configured base_commit: cloneenv
    podman image exists clb_configured_{{base_commit}} || \
    podman build configured \
        --tag clb_configured_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}} \
        --security-opt label=disable \
        --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

# Image with linux commit checked out, configured, and built. Not incremental.
clean_build base_commit: (configured base_commit)
    podman image exists clb_build_{{base_commit}} || \
    podman build clean_build \
        --tag clb_build_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}}

# Image with linux commit checked out, configured, and built. Incremental.
incremental_build base_commit target_commit:
    podman image exists clb_build_{{base_commit}}
    podman image exists clb_build_{{target_commit}} || \
    podman build incremental_build \
        --tag clb_build_{{target_commit}} \
        --build-arg BASE_COMMIT={{base_commit}} \
        --build-arg TARGET_COMMIT={{target_commit}} \
        --security-opt label=disable \
        --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

# Fedora bootable container with our kernel installed.
bootable target_commit: bootable_base
    podman image exists clb_build_{{target_commit}}
    podman image exists clb_bootable_{{target_commit}} || \
    podman build bootable \
        --tag clb_bootable_{{target_commit}} \
        --build-arg TARGET_COMMIT={{target_commit}} \

# Run the bootable container, automatically SSH in.
run target_commit: (bootable target_commit)
    bcvk ephemeral run-ssh --bind ./project:project clb_bootable_{{target_commit}}

# Run the bootable container, showing the serial console. Used for debugging boots.
run_console target_commit: (bootable target_commit)
    bcvk ephemeral run --console clb_bootable_{{target_commit}}

# Base image for all bootable images.
bootable_base:
    podman image exists clb_bootable_base || \
    podman build bootable_base \
        --tag clb_bootable_base \
