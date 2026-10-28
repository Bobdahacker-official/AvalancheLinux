#!/bin/sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Run with sudo on a Debian 13 build host.' >&2; exit 1; }
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
mkdir -p build artifacts
./scripts/build-packages.sh
# Never combine old chroots with a new configuration.
if [ -d build/chroot ]; then
  (cd build && lb clean --purge)
fi
rm -rf build/auto build/config
cp -a auto config build/
mkdir -p build/config/packages.chroot
cp artifacts/debs/*.deb build/config/packages.chroot/
cd build
export MKSQUASHFS_OPTIONS="-processors ${AVALANCHE_BUILD_JOBS:-2}"
lb config
lb bootstrap
# Optional trusted HTTPS-inspection bundle, scoped to the builder only.
if [ -n "${AVALANCHE_BUILD_CA:-}" ]; then
  [ -r "$AVALANCHE_BUILD_CA" ] || { echo 'Build CA bundle is unreadable.' >&2; exit 1; }
  for tree in chroot cache/bootstrap; do
    install -m 0644 "$AVALANCHE_BUILD_CA" "$tree/avalanche-build-ca.pem"
    printf 'Acquire::https::CaInfo "/avalanche-build-ca.pem";\n' > "$tree/etc/apt/apt.conf.d/99avalanche-build-ca"
  done
  mkdir -p config/rootfs
  printf 'avalanche-build-ca.pem\netc/apt/apt.conf.d/99avalanche-build-ca\n' >> config/rootfs/excludes
fi
lb build
set -- ./*.hybrid.iso
[ -f "$1" ] || { echo 'Build did not produce an ISO.' >&2; exit 1; }
cp -- "$@" "$root/artifacts/"
find . -maxdepth 1 -name "*.packages" -exec cp '{}' "$root/artifacts/" \;
cd "$root/artifacts"
set -- ./*.iso
[ -f "$1" ] || { echo 'Build did not produce an ISO.' >&2; exit 1; }
sha256sum ./*.iso > SHA256SUMS
printf 'Images and checksums: %s/artifacts\n' "$root"
