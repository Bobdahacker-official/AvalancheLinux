.PHONY: build packages check smoke
ISO ?= $(firstword $(wildcard artifacts/*.iso))
build:
	./scripts/build.sh
packages:
	./scripts/build-packages.sh
check:
	./scripts/check-image.sh "$(ISO)"
smoke:
	python3 scripts/boot-smoke.py "$(ISO)"
