# IoT Field example snaps

## Overview

This repository contains a collection of snaps created by the Devices Field
team. They are not generally recommended for production but instead act as
proof-of-concept examples for accomplishing particular tasks.

Each subdirectory is a different example, each with their own accompanying
READMEs which explain what they do, how they function, build instructions, and
potential limitations or ways to extend behavior.

## Snaps

### automount-actions

automount-actions is an example snap for acknowledging snaps and their
assertions on a device. The snaps and assertions are provided by a block device
(e.g. a USB stick). This device is automatically mounted and checked for the
correct files, and those files are then processed using the snapd REST API.

### daemon-control

daemon-control is a demonstration of how to orchestrate daemon startup between
snaps. the controlled-daemon can be any snap which provides daemons, and the
controller-daemon shows how one snap could control those daemons.

This example should be considered a solution until cross-snap daemon startup
ordering is supported by snapd.

### one-codebase-many-snaps

one-codebase-many-snaps shows how one could have a single repository build
multiple different snaps. The project uses a Makefile for demonstration purposes
but this could be extended to any build system or even scripting.

### qt-imx

qt-imx is a PoC snap for how to include proprietary graphics libraries and Qt
for displaying graphical elements to a display. The example specifically targets
the i.MX platform from NXP, but can be modified to cover other platforms.

## Contributing

You should sign the [Canonical contributor license agreement](https://ubuntu.com/legal/contributors).
