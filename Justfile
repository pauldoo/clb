# 6.19
#base_commit := "05f7e89ab9731565d8a62e3b5d1ec206485eeb0b"
# 2025-02-14: btrfs-devel/master
#base_commit := "44331bd6a610"

default:
    just --list

buildenv:
    podman image exists clb_buildenv || \
    podman build buildenv \
      --tag clb_buildenv \

cloneenv: buildenv
    podman image exists clb_cloneenv || \
    podman build cloneenv \
      --tag clb_cloneenv \
      --security-opt label=disable \
      --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

base_configured base_commit: cloneenv
    podman image exists clb_base_configured_{{base_commit}} || \
    podman build base_configured \
        --tag clb_base_configured_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}} \
        --security-opt label=disable \
        --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

base_build base_commit: (base_configured base_commit)
    podman image exists clb_base_build_{{base_commit}} || \
    podman build base_build \
        --tag clb_base_build_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}}

pkg_build base_commit target_commit: (base_build base_commit)
    podman image exists clb_pkg_build_{{target_commit}} || \
    podman build pkg_build \
        --tag clb_pkg_build_{{target_commit}} \
        --build-arg BASE_COMMIT={{base_commit}} \
        --build-arg TARGET_COMMIT={{target_commit}} \
        --security-opt label=disable \
        --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

bootable base_commit target_commit: (pkg_build base_commit target_commit) bootable_base
    podman image exists clb_bootable_{{target_commit}} || \
    podman build bootable \
        --tag clb_bootable_{{target_commit}} \
        --build-arg TARGET_COMMIT={{target_commit}} \

run base_commit target_commit: (bootable base_commit target_commit)
    bcvk ephemeral run-ssh clb_bootable_{{target_commit}}

run_debug base_commit target_commit:
    bcvk ephemeral run --console clb_bootable_{{target_commit}}

bootable_base:
    podman image exists clb_bootable_base || \
    podman build bootable_base \
        --tag clb_bootable_base \
