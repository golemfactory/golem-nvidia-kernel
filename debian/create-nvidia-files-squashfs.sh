#!/bin/bash

set -exu -o pipefail

squashfs_dir="$1"
packages_list="${2:-nvidia-kernel-common-570-server libnvidia-cfg1-570-server xserver-xorg-video-nvidia-570-server nvidia-compute-utils-570-server libnvidia-compute-570-server libnvidia-gl-570-server libnvidia-common-570-server nvidia-utils-570-server}"

# Make a packages array
read -r -a packages <<< "$packages_list"

# Cleanup
rm -rf "${squashfs_dir}"
mkdir -p "${squashfs_dir}"

# Create package files list
for pkg in "${packages[@]}"; do
    while read f; do [ ! -d "$f" ] && echo "$f"; done < <(dpkg -L "$pkg") | \
        sed \
            -e "/usr\/share\/doc/d;/usr\/share\/man/d" \
            -e "s:^/\(lib\|bin\|sbin\):/usr\0:" \
            >> "${squashfs_dir}/files.list"
done

# Copy only files from system to squashfs directory
rsync -av --files-from="${squashfs_dir}/files.list" / "${squashfs_dir}/"

# Create squashfs into parent directory
output_dir="$(dirname "${squashfs_dir}")"
mksquashfs "${squashfs_dir}" "${output_dir}/nvidia-files.squashfs" -e "${squashfs_dir}/files.list"
