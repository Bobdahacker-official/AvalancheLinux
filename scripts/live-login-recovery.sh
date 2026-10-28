#!/bin/sh
set -eu
# Runs inside the temporary live system, never against an installed disk.
id avalanche >/dev/null 2>&1 || useradd -m -s /bin/bash avalanche
printf 'avalanche:live\n' | chpasswd
usermod -aG sudo avalanche
mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\nautologin-user=avalanche\nautologin-user-timeout=0\nuser-session=avalanche\n' > /etc/lightdm/lightdm.conf.d/99-avalanche-recovery.conf
