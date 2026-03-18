# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains example snaps created by the Canonical Devices Field team. Each subdirectory is a standalone snap project demonstrating specific snap patterns and use cases. These are proof-of-concept examples, not production-ready snaps.

## Build Commands

Build any snap using LXD (recommended):
```bash
cd <snap-directory>
snapcraft pack --use-lxd --verbose
```

For cross-compilation with LXD (e.g., qt-imx for arm64):
```bash
snapcraft pack --use-lxd --build-for=arm64 --verbose
```

For qt-imx destructive mode (legacy, native build):
```bash
snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=arm64  # i.MX 8
snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=armhf  # i.MX 6
```

For one-codebase-many-snaps project:
```bash
cd one-codebase-many-snaps
make snap-a SNAPCRAFTFLAGS=--use-lxd
make snap-b SNAPCRAFTFLAGS=--use-lxd
```

## Core Version Branches

This repository maintains separate branches for different snap bases:
- Branch `20`: core20 (Ubuntu 20.04)
- Branch `22`: core22 (Ubuntu 22.04)
- Branch `24`: core24 (Ubuntu 24.04)
- Branch `26`: core26 (Ubuntu 26.04)

### Variable and Syntax Differences

| Feature | core20 | core22 | core24/core26 |
|---------|--------|--------|---------------|
| Variables | `SNAPCRAFT_*` | `CRAFT_*` | `CRAFT_*` |
| Default action | `snapcraftctl default` | `craftctl default` | `craftctl default` |
| Arch triplet | `SNAPCRAFT_ARCH_TRIPLET` | `CRAFT_ARCH_TRIPLET_BUILD_FOR` | `CRAFT_ARCH_TRIPLET_BUILD_FOR` |
| Target arch | `SNAPCRAFT_TARGET_ARCH` | `CRAFT_TARGET_ARCH` | `CRAFT_TARGET_ARCH` |
| Part source | `SNAPCRAFT_PART_SRC` | `CRAFT_PART_SRC` | `CRAFT_PART_SRC` |
| Part install | `SNAPCRAFT_PART_INSTALL` | `CRAFT_PART_INSTALL` | `CRAFT_PART_INSTALL` |
| Project dir | `SNAPCRAFT_PROJECT_DIR` | `CRAFT_PROJECT_DIR` | `CRAFT_PROJECT_DIR` |
| Stage dir | `${SNAPCRAFT_PROJECT_DIR}/stage` | `${CRAFT_STAGE}` | `${CRAFT_STAGE}` |
| Architecture key | N/A | `architectures` (list) | `platforms` (dict) |

### Architecture Key Formats

**core22** uses `architectures` (list format):
```yaml
architectures:
  - build-on: [amd64]
    build-for: [arm64]
```

**core24/core26** uses `platforms` (dict format):
```yaml
platforms:
  arm64:
    build-on: [amd64]
    build-for: [arm64]
```

### Library Versions by Ubuntu Release

| Package | 20.04 | 22.04 | 24.04 | 26.04 |
|---------|-------|-------|-------|-------|
| libicu | libicu66 | libicu70 | libicu74 | libicu76+ |
| libffi | libffi7 | libffi8 | libffi8 | libffi8 |
| libsepol | libsepol1 | libsepol2 | libsepol2 | libsepol2 |

## Snap Projects

| Directory | Snap Name | Description |
|-----------|-----------|-------------|
| automount-actions | automount-actions | Auto-mount USB, sideload asserted snaps via snapd REST API |
| basic-server | basic-server | TCP server on configurable port using ncat |
| daemon-control/ | test-controlled-daemons, test-controller-daemons | Cross-snap daemon orchestration via snapd-control interface |
| one-codebase-many-snaps | snap-a, snap-b | Multi-snap build from single repository using Makefile |
| qt-imx | itrue-qt-imx-snap | Qt5 libraries for i.MX 6/8 SoCs with eglfs backend |
| using-docker | tocker | Docker container orchestration on Ubuntu Core |

## Key Interfaces

- **mount-control**: Required by automount-actions for USB mounting
- **snapd-control**: Required for cross-snap daemon control via REST API (super-privileged)
- **docker/docker-executables**: Required by using-docker for Docker snap interaction

## qt-imx Cross-Compilation Notes

The qt-imx snap builds Qt 5.6.3 from source for i.MX ARM platforms. Critical configuration:

1. **Sysroot path**: Must use `${CRAFT_STAGE}` (not `${CRAFT_PROJECT_DIR}/stage`)
2. **XCB/X11**: Use `-no-xcb` for embedded eglfs-only builds (remove `-qt-xcb` and `-qt-xkbcommon-x11`)
3. **Staging conflicts**: Add `stage: - -lib` to hello-world part to avoid conflicts with dependencies part
4. **Patch file**: `0001-Added-linux-imx8-g.patch` must include OpenGL ES paths:
   ```
   QMAKE_INCDIR_EGL        = $$[QT_SYSROOT]/usr/include
   QMAKE_LIBDIR_EGL        = $$[QT_SYSROOT]/usr/lib/aarch64-linux-gnu
   QMAKE_INCDIR_OPENGL_ES2 = $$[QT_SYSROOT]/usr/include
   QMAKE_LIBDIR_OPENGL_ES2 = $$[QT_SYSROOT]/usr/lib/aarch64-linux-gnu
   ```
5. **Patch line counts**: If modifying the patch, update the line counts in headers (`@@ -0,0 +1,27 @@`)

## LXD Networking Issues

If snapcraft builds fail with DNS resolution errors in LXD containers:
```bash
# Fix: Disable IPv6 on LXD bridge (IPv6 NAT often misconfigured)
lxc network set lxdbr0 ipv6.address none
```

## Commit Message Format

```
<example-name>: short description

Details if required

Signed-off-by: Name <email>
```

Use `git commit -s` to add signoff. For root files, use the filename (e.g., `README`, `gitignore`).
