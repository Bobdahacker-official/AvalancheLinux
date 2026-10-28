# AvalancheLinux source

`avalanche-core/` contains the Avalanche command, desktop applications, session, launchers, software catalog, desktop assets, and installation finalization helper.

`avalanche-installer/` contains the installer launcher, Calamares settings, installation slides, branding, and authorization policy.

Each directory follows its package's installed filesystem layout. Executable application code is under `usr/bin/` and `usr/lib/`; package metadata is under `DEBIAN/`.

Run `make packages` from the repository root to build both packages. Distribution build tools and live-image configuration remain in the root `scripts/`, `auto/`, and `config/` directories.
