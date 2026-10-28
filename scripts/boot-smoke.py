#!/usr/bin/env python3
"""Boot the ISO, then check the running graphical session through QEMU's agent."""
import argparse
import base64
import json
import pathlib
import socket
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('iso', type=pathlib.Path)
parser.add_argument('--timeout', type=int, default=360)
parser.add_argument('--uefi', action='store_true')
parser.add_argument('--screenshot', type=pathlib.Path)
args = parser.parse_args()


def rpc(stream, name, arguments=None):
    request = {'execute': name}
    if arguments is not None:
        request['arguments'] = arguments
    stream.write((json.dumps(request) + '\n').encode())
    stream.flush()
    result = json.loads(stream.readline())
    if 'error' in result:
        raise RuntimeError(result['error'])
    return result['return']


with tempfile.TemporaryDirectory(prefix='avalanche-boot-') as tmp:
    serial = pathlib.Path(tmp) / 'serial.log'
    agent = pathlib.Path(tmp) / 'agent.sock'
    command = ['qemu-system-x86_64', '-accel', 'tcg', '-m', '2048', '-smp', '2',
               '-cdrom', str(args.iso.resolve()), '-boot', 'd', '-display', 'none',
               '-serial', f'file:{serial}', '-no-reboot', '-nic', 'user,model=virtio-net-pci',
               '-device', 'virtio-serial-pci',
               '-chardev', f'socket,path={agent},server=on,wait=off,id=qga',
               '-device', 'virtserialport,chardev=qga,name=org.qemu.guest_agent.0']
    if args.uefi:
        command += ['-bios', '/usr/share/OVMF/OVMF_CODE_4M.fd']
    process = subprocess.Popen(command)
    try:
        deadline = time.monotonic() + args.timeout
        sock = None
        stream = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise SystemExit(f'QEMU exited with {process.returncode}')
            try:
                sock = socket.socket(socket.AF_UNIX)
                sock.settimeout(3)
                sock.connect(str(agent))
                stream = sock.makefile('rwb')
                rpc(stream, 'guest-ping')
                break
            except (OSError, ValueError):
                if stream is not None:
                    stream.close()
                if sock is not None:
                    sock.close()
                time.sleep(2)
        else:
            log = serial.read_text(errors='replace') if serial.exists() else ''
            raise SystemExit(f'Guest-agent startup deadline exceeded:\n{log[-8000:]}')
        sock.settimeout(60)
        with sock:
            with stream:
                # Wait for LightDM's auto-login to create the actual Xfce session.
                check = '''set -eu
for i in $(seq 1 120); do
    if pgrep -x xfce4-session >/dev/null; then break; fi
    sleep 2
done
pgrep -x Xorg
pgrep -x xfce4-session
systemctl is-active graphical.target lightdm NetworkManager
ip -4 route show default | grep default
. /etc/os-release
[ "$ID" = avalanche ]
[ "$(cat /etc/hostname)" = avalanche ]
[ "$(dpkg-divert --truename /usr/lib/os-release)" = /usr/lib/os-release.debian ]
dpkg-query -W apt synaptic firefox-esr
apt-get --simulate install nano
free -m
printf 'AVALANCHE_DESKTOP_OK\\n'
'''
                pid = rpc(stream, 'guest-exec', {'path': '/bin/sh', 'arg': ['-c', check], 'capture-output': True})['pid']
                while time.monotonic() < deadline:
                    result = rpc(stream, 'guest-exec-status', {'pid': pid})
                    if result.get('exited'):
                        output = base64.b64decode(result.get('out-data', '')).decode(errors='replace')
                        errors = base64.b64decode(result.get('err-data', '')).decode(errors='replace')
                        print(output)
                        if result.get('exitcode') != 0 or 'AVALANCHE_DESKTOP_OK' not in output:
                            raise SystemExit(f'Guest desktop checks failed: {result}\n{errors}')
                        manager = rpc(stream, 'guest-exec', {
                            'path': '/usr/bin/env',
                            'arg': ['DISPLAY=:0', 'XAUTHORITY=/home/avalanche/.Xauthority', '/usr/bin/avalanche-center', '--page', 'software'],
                            'capture-output': True})['pid']
                        time.sleep(8)
                        manager_state = rpc(stream, 'guest-exec-status', {'pid': manager})
                        if manager_state.get('exited'):
                            raise SystemExit(f'Avalanche Software exited before its GUI check: {manager_state}')
                        print('Avalanche Software opened successfully.')
                        if args.screenshot:
                            time.sleep(5)
                            capture = rpc(stream, 'guest-exec', {
                                'path': '/usr/sbin/runuser',
                                'arg': ['-u', 'avalanche', '--', 'env', 'DISPLAY=:0',
                                        'XAUTHORITY=/home/avalanche/.Xauthority',
                                        'xfce4-screenshooter', '-f', '-s', '/tmp/avalanche-desktop.png'],
                                'capture-output': True})['pid']
                            for _ in range(30):
                                captured = rpc(stream, 'guest-exec-status', {'pid': capture})
                                if captured.get('exited'):
                                    if captured.get('exitcode') != 0:
                                        raise SystemExit(f'Screenshot failed: {captured}')
                                    break
                                time.sleep(1)
                            else:
                                raise SystemExit('Screenshot deadline exceeded.')
                            handle = rpc(stream, 'guest-file-open', {'path': '/tmp/avalanche-desktop.png', 'mode': 'rb'})
                            try:
                                with args.screenshot.open('wb') as output_file:
                                    while True:
                                        chunk = rpc(stream, 'guest-file-read', {'handle': handle, 'count': 1048576})
                                        output_file.write(base64.b64decode(chunk['buf-b64']))
                                        if chunk['eof']:
                                            break
                            finally:
                                rpc(stream, 'guest-file-close', {'handle': handle})
                            print(f'Desktop screenshot: {args.screenshot}')
                        print('Live desktop, networking service and APT passed under QEMU.')
                        break
                    time.sleep(2)
                else:
                    raise SystemExit('Guest functional checks exceeded the boot deadline.')
    finally:
        process.terminate()
        process.wait(timeout=15)
