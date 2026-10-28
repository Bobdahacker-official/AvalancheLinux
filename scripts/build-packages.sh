#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$root/artifacts/debs"
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT HUP INT TERM
for package in avalanche-core avalanche-installer; do
  cp -a "$root/packages/$package" "$staging/$package"
  mkdir -p "$staging/$package/usr/share/doc/$package"
  cp "$root/LICENSE" "$staging/$package/usr/share/doc/$package/copyright"
  find "$staging/$package" -type d -name __pycache__ -prune -exec rm -rf '{}' +
  find "$staging/$package" -type d -exec chmod 755 '{}' +
  find "$staging/$package" -type f -exec chmod 644 '{}' +
  chmod 755 "$staging/$package/usr/bin/"*
  if [ "$package" = avalanche-core ]; then
    chmod 755 "$staging/$package/usr/lib/avalanche/finalize-install"
  else
    chmod 755 "$staging/$package/usr/lib/avalanche-installer/launch"
  fi
  dpkg-deb --root-owner-group --build "$staging/$package" "$root/artifacts/debs/${package}_1.0-1_all.deb"
done
