# 6.19
#base_commit := "05f7e89ab9731565d8a62e3b5d1ec206485eeb0b"
# 2025-02-14: btrfs-devel/master
base_commit := "44331bd6a610"

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

base_configured: cloneenv copy-host-config
    podman image exists clb_base_configured_{{base_commit}} || \
    podman build base_configured \
        --tag clb_base_configured_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}} \
        --security-opt label=disable \
        --volume {{justfile_directory()}}/linux/.git:/host-repo:ro

base_build: base_configured
    podman image exists clb_base_build_{{base_commit}} || \
    podman build base_build \
        --tag clb_base_build_{{base_commit}} \
        --build-arg BASE_COMMIT={{base_commit}}

copy-host-config:
    cp -v /usr/src/kernels/*/.config ./base_configured/kernel.config
    sed -i '/CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE/c\# CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE is not set' ./base_configured/kernel.config
    sed -i '/CONFIG_CC_OPTIMIZE_FOR_SIZE/c\CONFIG_CC_OPTIMIZE_FOR_SIZE=y' ./base_configured/kernel.config
