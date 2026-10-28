# Avalanche architecture

AvalancheLinux has a distribution layer and two installable first-party packages.

`avalanche-core` provides the `avalanche` command, native GTK Avalanche Center, Software, Updates and Settings, an application collection catalog, the Avalanche desktop session, launcher integration, first-login welcome, product icon, GRUB product identity and installed-system finalization. Package operations use APT as the transaction engine. Collections expand into concrete packages; arbitrary package names are validated and commands execute as argument arrays. The desktop runs without root privileges; package changes authenticate in a terminal.

`avalanche-installer` provides the Calamares workflow, Avalanche product assets, installation slideshow, module settings and a dedicated privilege policy. Its root launcher runs a fixed installer executable. The workflow copies the live SquashFS, configures disks, users, networking and the display manager, removes live components, regenerates initramfs and installs GRUB. Installation packages are removed from the target. The core package's finalization helper remains available throughout this sequence.

`config/` supplies the boot menu, login theme, default panel, wallpaper and live-image package selection. The default LightDM session is `avalanche`, which starts the Xfce session under Avalanche's product identity and defaults. The installer is launched from the desktop; the separate Debian Installer boot environment is disabled.

The kernel, system libraries and signed package archive follow Debian 13 trixie. A dpkg diversion preserves Avalanche's operating-system identity across base-files updates. Archive URLs and platform compatibility identifiers deliberately remain correct; upstream attribution and package licenses are preserved.

`make packages` produces the first-party .deb files. `make build` installs them into a clean live-build tree and emits the bootable image. Builds run explicitly, rather than automatically for every source change. Diagnostics and optional image checks belong to release preparation, not the normal user experience.
