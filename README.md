# AvalancheLinux

AvalancheLinux is a lightweight Linux desktop built on Debian 13 and Xfce. It adds Avalanche applications for software, updates, settings, and system management, along with a custom desktop session and Calamares installer.

## Download

Get the bootable ISO from [Releases](https://github.com/Bobdahacker-official/AvalancheLinux/releases). Write it to a USB drive to start AvalancheLinux and install it on your computer.

- **avalanche-core** includes Avalanche Center, Software, Updates, Settings, the desktop session, and the `avalanche` command.
- **avalanche-installer** includes the graphical installer workflow, product screens, and desktop launcher. Use it when building an Avalanche live image.

The ISO includes the Avalanche applications and graphical installer. The separate packages are also available for developers and existing installations.

## Install the desktop applications

On Debian 13, download `avalanche-core_1.0-1_all.deb`, open a terminal in the download folder, and run:

```sh
sudo apt install ./avalanche-core_1.0-1_all.deb
```

Open **Avalanche Center** from the applications menu.

## What’s included

- **Avalanche Center** brings software, settings, updates, and installation into one window.
- **Avalanche Software** installs application collections and searches the full package archive.
- **Avalanche Settings** opens display, network, sound, power, appearance, and keyboard controls. It also checks system health.
- **Avalanche Updates** refreshes package information and starts system upgrades.
- **Avalanche Installer** guides you through language, keyboard, disk, and account setup, then installs the system and bootloader.
- **Avalanche Desktop** adds a session, panel, welcome screen, wallpaper, login theme, and boot menu.

Software changes use APT. You review the package transaction and authenticate before installation.

## Use the terminal

```sh
avalanche collections            # List application collections
avalanche install @office        # Install LibreOffice and a dictionary
avalanche install @development   # Install compilers, Git, Python tools, and GDB
avalanche search photo           # Search the package archive
avalanche info gimp              # Show package details
avalanche install gimp           # Install a package
avalanche remove gimp            # Remove a package
avalanche list                   # List installed packages
avalanche upgrade                # Refresh package information and apply updates
avalanche doctor                 # Check services, disk space, and package health
```

Use `avalanche --help` for the full command list.

## Build the packages

Install `make` and `dpkg` on a Linux build host, then run:

```sh
make packages
```

The two `.deb` files are written to `artifacts/debs/`. Application and installer source is in [packages](packages/).

## Build a live image

Use a Debian 13 amd64 host with root access, 4 GB of RAM, and at least 25 GB of free disk space.

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends live-build debootstrap ca-certificates \
  xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin \
  mtools dosfstools squashfs-tools python3 make
sudo make build
```

The build creates the Avalanche packages, installs them in the live filesystem, and writes a BIOS/UEFI ISO, package list, and checksums to `artifacts/`.

To use eight compression workers on a larger machine:

```sh
sudo AVALANCHE_BUILD_JOBS=8 make build
```

For a network that inspects HTTPS, set `AVALANCHE_BUILD_CA` to the path of its trusted CA bundle. The build excludes that bundle and its configuration from the image.

Image builds run when you start them. Source changes don’t trigger image builds or VM tests.

## Install from a live image

1. Back up your files.
2. Write the ISO to a USB drive with a raw-image writer. This erases the USB drive.
3. Turn off firmware Secure Boot and boot the USB drive.
4. Choose **Start AvalancheLinux**.
5. Open **Install AvalancheLinux** in Avalanche Center.
6. Review the partition summary before confirming changes to the disk.

The live account is `avalanche`, with password `live`. The installer creates your permanent account.

## Project details

Debian supplies the kernel, system libraries, and signed package archive. Xfce supplies the desktop components, and Calamares supplies the installer engine. Avalanche’s applications, software catalog, session, and distribution settings live in this repository.

Avalanche’s original code and artwork use the [MIT license](LICENSE). Upstream software keeps its own licenses and copyright notices.

Read the [architecture](docs/architecture.md), [upstream research](docs/research.md), and [release process](docs/releasing.md). Report problems in [Issues](https://github.com/Bobdahacker-official/AvalancheLinux/issues).
