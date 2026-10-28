# Upstream research

AvalancheLinux follows the Debian live-image architecture and uses its existing signed package archive rather than creating a second package ecosystem.

- [Debian live-build upstream](https://github.com/debian-live/live-build): reproducible image configuration, package lists, chroot hooks, hybrid images, and Debian Installer integration. The upstream README and the Debian branch’s package-customization and installer chapters were retrieved during implementation; the installed Debian 13 live-build manual is the command-option reference.
- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html): live sessions, customization, and installer integration.
- [Debian 13 release information](https://www.debian.org/releases/trixie/): stable base and release lifecycle.
- [Xfce documentation](https://docs.xfce.org/): desktop components and Xfconf settings.
- [Debian package archive](https://deb.debian.org/debian/): build tools, kernel, desktop packages, and firmware. APT checks signed archive metadata and package hashes.
- [Calamares configuration](https://github.com/calamares/calamares/blob/calamares/settings.conf), [filesystem deployment](https://github.com/calamares/calamares/blob/calamares/src/modules/unpackfs/unpackfs.conf), [users](https://github.com/calamares/calamares/blob/calamares/src/modules/users/users.conf), [initramfs](https://github.com/calamares/calamares/blob/calamares/src/modules/initramfs/initramfs.conf), and [job execution](https://github.com/calamares/calamares/blob/calamares/src/modules/shellprocess/shellprocess.conf) were retrieved and read to implement Avalanche Installer. The packaged upstream integration was inspected for mount, fstab and bootloader behavior. Avalanche owns its module sequence, product identity, slideshow and launcher.
- [GTK 3](https://docs.gtk.org/gtk3/) and [APT](https://www.debian.org/doc/manuals/apt-guide/) supply the UI toolkit and signed package transaction engine for Avalanche's native applications and CLI.

Research date: 28 October 2026. User-facing Avalanche tools are implemented in this repository; technical compatibility identifiers, archive destinations, and upstream license notices retain their correct names.
