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

copy-host-config:
    cp -v /usr/src/kernels/*/.config ./base_configured/kernel.config
    sed -i '/CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE/c\# CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE is not set' ./base_configured/kernel.config
    sed -i '/CONFIG_CC_OPTIMIZE_FOR_SIZE/c\CONFIG_CC_OPTIMIZE_FOR_SIZE=y' ./base_configured/kernel.config
    sed -i '/CONFIG_EFI_SBAT=/c\CONFIG_EFI_SBAT=n' ./base_configured/kernel.config
    sed -i '/CONFIG_EFI_SBAT_FILE=/c\# CONFIG_EFI_SBAT_FILE is not set' ./base_configured/kernel.config
