# qt-imx-snap

***Notice**: This is an example and should not be used in production.*

## Overview

Qt application libraries compiled with support for the eglfs backend on i.MX 6 & 8 SoCs.

Users can either use this snap in `stage-snaps` to utilise the prebuilt libraries for their application, or extend this snap by adding the appropriate build steps.

The Qt libraries are installed to the `${SNAP}/usr/` prefix.

As part of the build process, the GPU library binaries for the SoCs are downloaded, extracted, and added to the snap. It's assumed you know what you're doing, license-wise, if you're using and/or distributing this snap.

## Building

This snap can be built on an amd64-based PC with the following command:

    # for i.MX 6
    snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=armhf
    # for i.MX 8
    snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=arm64

This snap can also be built natively on the target devices using the typical snapcraft build process. Please note that this will take quite a bit of time, as the Qt libraries are rather large.
