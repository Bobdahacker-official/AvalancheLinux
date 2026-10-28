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
boot_options=(-boot menu=on)
if [ "${1:-}" = '--recover-login' ]; then
    if ! command -v xorriso >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends xorriso
    fi
    recovery_iso="$state/login-recovery.iso"
    # Keep the downloaded ISO and virtual disk intact. Change only a new copy.
    if [ ! -f "$recovery_iso" ]; then
        xorriso -indev "$iso" -outdev "$recovery_iso.part" \
            -map "$root/scripts/live-login-recovery.sh" /live/config-hooks/9999-recover-login \
            -boot_image any replay
        mv "$recovery_iso.part" "$recovery_iso"
    fi
    xorriso -osirrox on -indev "$recovery_iso" \
        -extract /live/vmlinuz "$state/recovery-vmlinuz" \
        -extract /live/initrd.img "$state/recovery-initrd.img"
    iso="$recovery_iso"
    boot_options=(-kernel "$state/recovery-vmlinuz" -initrd "$state/recovery-initrd.img"
        -append 'boot=live components username=avalanche hostname=avalanche hooks=medium')
    echo 'Recovery mode: live desktop login is avalanche / live; automatic login is enabled.'
fi
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
    "${boot_options[@]}" -device virtio-vga -device usb-ehci -device usb-tablet \
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
