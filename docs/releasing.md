# Release process

1. Update the first-party package versions, application catalog and release notes together.
2. Run `make packages` to create the native application and installer packages.
3. Run one `sudo make build` after integration. This includes the current packages in the image.
4. For release acceptance, check the image contents and exercise the live desktop and Calamares installation on a disposable test disk. Check package transactions, network, audio and reboot from the installed disk. Record the actual results with the release.
5. Publish the ISO, first-party .deb files, package manifest and SHA256SUMS. Sign the checksums using the project's release key, kept outside the image builder.

The GitHub image workflow is manual. Optional developer image and VM checks can be invoked during release acceptance; ordinary source edits do not trigger image rebuilds or VM loops.

Upstream package copyright and license files remain in `/usr/share/doc`. Distribute corresponding source and notices in accordance with package licenses. Maintain the source of the first-party packages alongside each release.

## Publish a package release

Write the release notes in `docs/releases/<tag>.md`, commit the source, and push a version tag. The release workflow builds the two Avalanche packages, creates their checksums, and publishes them with those notes. It does not build an ISO or start VM tests.

The README and release notes follow [Microsoft’s style and voice guidance](https://learn.microsoft.com/en-us/style-guide/top-10-tips-style-voice): lead with the useful information, use familiar words, and keep sentences and headings short.
