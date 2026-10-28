#!/usr/bin/env python3
"""Repair the running live VM through its local guest-agent socket."""
import json
import socket
import sys
import time

path = sys.argv[1]
deadline = time.monotonic() + 600
command = """set -eu
test -d /run/live/medium || test -d /lib/live/mount/medium
id avalanche >/dev/null
systemctl is-active --quiet lightdm
printf 'avalanche:live\\n' | chpasswd
passwd -u avalanche >/dev/null 2>&1 || true
chage -E -1 -M 99999 avalanche
mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\\nautologin-user=avalanche\\nautologin-user-timeout=0\\nuser-session=avalanche\\n' > /etc/lightdm/lightdm.conf.d/99-avalanche-recovery.conf
systemctl restart --no-block lightdm
"""

def request(stream, name, args=None):
    payload = {"execute": name}
    if args is not None:
        payload["arguments"] = args
    stream.write((json.dumps(payload) + "\n").encode())
    stream.flush()
    while True:
        line = stream.readline()
        if not line:
            raise OSError("Guest connection closed")
        response = json.loads(line)
        if "error" in response:
            raise OSError(str(response["error"]))
        if "return" in response:
            return response["return"]

print('Waiting for the live desktop to start so its account can be repaired…', flush=True)
while time.monotonic() < deadline:
    try:
        with socket.socket(socket.AF_UNIX) as sock:
            sock.settimeout(5)
            sock.connect(path)
            with sock.makefile('rwb') as stream:
                result = request(stream, 'guest-exec', {
                    'path': '/bin/sh', 'arg': ['-c', command], 'capture-output': True})
                for _ in range(30):
                    status = request(stream, 'guest-exec-status', {'pid': result['pid']})
                    if status.get('exited'):
                        if status.get('exitcode') == 0:
                            print('Login repaired inside the running VM. Refresh noVNC. Username: avalanche; password: live.', flush=True)
                            sys.exit(0)
                        break
                    time.sleep(1)
    except (OSError, ValueError):
        pass
    time.sleep(5)
print('Repair could not reach the live desktop. Share artifacts/codespace/qemu.log and repair.log.', flush=True)
sys.exit(1)
