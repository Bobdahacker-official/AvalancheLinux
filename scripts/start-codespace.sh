#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
state="$root/artifacts/codespace"
mkdir -p "$state"

if ! command -v qemu-system-x86_64 >/dev/null || ! command -v websockify >/dev/null || [ ! -f /usr/share/novnc/vnc.html ]; then
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils novnc websockify curl ca-certificates
fi

iso="$state/avalanchelinux-1.0-amd64.hybrid.iso"
if [ ! -s "$iso" ]; then
    echo 'Downloading the AvalancheLinux boot image…'
    if ! curl --fail --location --retry 3 --output "$iso.part" \
        https://github.com/Bobdahacker-official/AvalancheLinux/releases/download/v1.0.0/avalanchelinux-1.0-amd64.hybrid.iso; then
        echo 'The ISO download is not ready. Let the GitHub image build finish, then run this command again.' >&2
        exit 1
    fi
    mv "$iso.part" "$iso"
fi
disk="$state/avalanche.qcow2"
if [ ! -f "$disk" ]; then
    qemu-img create -f qcow2 "$disk" 20G
fi

acceleration=(-accel tcg,thread=multi)
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    acceleration=(-accel kvm -cpu host)
fi
vm_pid=''
web_pid=''
cleanup() {
    [ -z "$web_pid" ] || kill "$web_pid" 2>/dev/null || true
    [ -z "$vm_pid" ] || kill "$vm_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM
qemu-system-x86_64 "${acceleration[@]}" -m 2048 -smp 2 \
    -drive "file=$disk,format=qcow2,if=virtio" -cdrom "$iso" \
    -boot menu=on -device virtio-vga -device usb-ehci -device usb-tablet \
    -nic user,model=virtio-net-pci -display none -vnc 127.0.0.1:1 \
    >"$state/qemu.log" 2>&1 &
vm_pid=$!
websockify --web=/usr/share/novnc 6080 127.0.0.1:5901 \
    >"$state/novnc.log" 2>&1 &
web_pid=$!
if [ -n "${CODESPACE_NAME:-}" ]; then
    echo "Open https://${CODESPACE_NAME}-6080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}/vnc.html?autoconnect=true&resize=scale"
else
    echo 'Open http://localhost:6080/vnc.html?autoconnect=true&resize=scale'
fi
echo 'Keep this terminal open. Press Ctrl+C to stop. Keep port 6080 private.'
echo 'The first boot can take several minutes. Choose Start AvalancheLinux in the boot menu.'
wait -n "$vm_pid" "$web_pid"
