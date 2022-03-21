# qt-imx-snap

## Overview

Qt application libraries compiled with support for the eglfs backend on i.MX 6 & 8 SoCs.

Users can either use this snap in `stage-snaps` to utilise the prebuilt libraries for their application, or extend this snap by adding the appropriate build steps.

The Qt libraries are available in the /usr/local/qt5 directory in the snap.

As part of the build process, the GPU library binaries for the SoCs are downloaded, extracted, and added to the snap. It's assumed you know what you're doing, license-wise, if you're using and/or distributing this snap.

## Building

This snap can be built on an amd64-based PC with the following command:

    # for i.MX 6
    snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=armhf
    # for i.MX 8
    snapcraft --destructive-mode --enable-experimental-target-arch --target-arch=arm64
