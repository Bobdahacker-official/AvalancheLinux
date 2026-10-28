#!/bin/sh
set -eu
iso=$(realpath "${1:?Usage: scripts/check-image.sh artifacts/image.iso}")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
xorriso -osirrox on -indev "$iso" -extract /live/filesystem.squashfs "$tmp/rootfs" >/dev/null 2>&1
if unsquashfs -ll "$tmp/rootfs" | grep -E 'avalanche-build-ca|99avalanche-build-ca'; then
  echo 'Build-only CA configuration leaked into image.' >&2
  exit 1
fi
unsquashfs -cat "$tmp/rootfs" etc/os-release | grep -q 'ID=avalanche'
unsquashfs -cat "$tmp/rootfs" etc/calamares/settings.conf | grep -q 'branding: avalanche'
unsquashfs -cat "$tmp/rootfs" var/lib/dpkg/diversions | grep -q '/usr/lib/os-release.debian'
unsquashfs -cat "$tmp/rootfs" var/lib/dpkg/status > "$tmp/packages"
python3 - "$tmp/packages" <<'PY'
import sys
from pathlib import Path
packages = {}
for stanza in Path(sys.argv[1]).read_text().split('\n\n'):
    fields = dict(line.split(': ', 1) for line in stanza.splitlines() if ': ' in line and not line.startswith(' '))
    if fields.get('Status') == 'install ok installed':
        packages[fields['Package']] = fields.get('Version')
for name in ['linux-image-amd64', 'live-boot', 'live-config', 'xfce4', 'lightdm', 'xserver-xorg', 'lxpolkit', 'libgl1-mesa-dri', 'qemu-guest-agent', 'network-manager', 'apt', 'avalanche-core', 'avalanche-installer', 'calamares', 'synaptic', 'firefox-esr']:
    assert name in packages, f'Missing installed package: {name}'
    print(f'{name}: {packages[name]}')
PY
xorriso -indev "$iso" -report_el_torito plain 2>&1 | tee "$tmp/boot"
grep -q BIOS "$tmp/boot"
grep -q UEFI "$tmp/boot"
printf 'Image contents, desktop packages, BIOS and UEFI boot entries passed.\n'
