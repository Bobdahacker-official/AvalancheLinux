# RawLinux 1.0

Minimal x86-64 Linux: an upstream Linux 6.12 kernel, a statically linked BusyBox ash shell, and basic command-line utilities. Boots directly to a root prompt. No Debian root filesystem, desktop, installer, package manager, or network services.

## Boot

Attach `RawLinux-1.0-x86_64.iso` as a virtual CD in an x86-64 VM with legacy BIOS and at least 128 MB RAM. Secure Boot and UEFI boot are not supported by this image.

With QEMU (press `s` at the boot menu to select the serial console):

```sh
qemu-system-x86_64 -m 128 -cdrom RawLinux-1.0-x86_64.iso -nographic
```

Alternatively, boot the supplied kernel and initramfs directly:

```sh
qemu-system-x86_64 -m 128 -kernel RawLinux-vmlinuz \
  -initrd RawLinux-initramfs.cpio.gz -append 'console=ttyS0,115200 quiet' -nographic
```

The prompt is `RawLinux:#`. Try `ls`, `uname -a`, `cat /etc/os-release`, or `vi`. Use `poweroff -f` to shut down; exiting the shell also shuts down. QEMU's Ctrl+A, then X exits the emulator.

This is an in-memory system. Files disappear when powered off. There is no disk installer or persistent storage configuration. Hardware support is deliberately limited to the console, keyboard, and boot essentials.

## Download source archive

`RawLinux-1.0-source.tar.gz` is one complete archive, stored with Git LFS to support its size. Use the file's Download button on GitHub, or clone this branch with Git LFS installed and run `git lfs pull`.

```sh
sha256sum -c SOURCE-SHA256SUMS
tar -xzf RawLinux-1.0-source.tar.gz
```

`SHA256SUMS` verifies the files in this folder.

## Rebuild

Extract `RawLinux-1.0-source.tar.gz`, enter `source`, and run `./build.sh` on an x86-64 Linux build host. Dependencies: GCC/binutils, make, flex, bison, m4, bc, Perl, Python 3, gzip, tar, musl-gcc and musl development files, libelf development files, GRUB tools with i386-pc modules, and xorriso. This build host used Debian-provided tools; the booted Linux userspace is compiled from upstream BusyBox with musl, without a Debian base.

The source archive includes the exact upstream Linux and BusyBox archives, final configurations, startup files, build script, and the source package corresponding to the GRUB bootloader. License notices are in `source/licenses`. Linux and BusyBox use GPLv2; GRUB uses GPLv3+; musl uses MIT terms. RawLinux's original startup/build scripts are provided under GPLv2.

## Sources researched

- Linux kernel source: https://github.com/torvalds/linux/tree/v6.12
- Linux initramfs documentation: https://www.kernel.org/doc/html/latest/filesystems/ramfs-rootfs-initramfs.html
- Early userspace: https://docs.kernel.org/driver-api/early-userspace/early_userspace_support.html
- BusyBox overview: https://busybox.net/about.html
- BusyBox source mirror, pinned commit: https://github.com/mirror/busybox/tree/371fe9f71d445d18be28c82a2a6d82115c8af19d

Versions are pinned for this build; this image does not provide an update mechanism.

## Validation

The final ISO was booted under QEMU through GRUB's serial-console entry. The interactive shell ran `uname -a`, read `/etc/os-release`, printed a confirmation, and shut down with `poweroff -f`. This checks VM boot and shell operation; physical hardware and UEFI were not tested.
