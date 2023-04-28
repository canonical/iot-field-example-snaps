# Automount USB drives and sideload asserted snaps

_Canonical Devices and IoT, Field Engineering_


Version: 1.3


## Introduction

This document explains a snap (automount-actions) that automatically installs
asserted snaps from a USB drive on insertion. Installing a snap with its
assertion file is called “sideloading.”

This is a **reference** implementation of a snap which can automount USB drives
and sideload snaps. The source files are meant to be modified and incorporated
into other snaps.

The source for the automount-actions snap can be found
[here](https://github.com/canonical/iot-field-example-snaps/tree/main/automount-actions).


## Architecture

This snap uses the `mount-control` interface to mount block devices of a
particular naming scheme (`sdX`) of a particular filesystem (`vfat`) with a
particular set of mount options (`rw,sync`) to a particular directory
(`/tmp/tmp.XXXXXXXXXX/<UUID>`). When a drive is mounted, if it contains both a
snap and its corresponding assertion, the assertions are acknowledged and the
snaps installed. Each snap is set to follow the stable channel. Logs are written
to the snap's temporary directory (`/tmp/tmp.XXXXXXXXXX/$(date -Iseconds).log`)
and copied to the block device during cleanup steps.


### Implementation details

The snap’s `auto-mount` simple daemon checks for block device UUID creation using
`inotifywait`, mounts those devices, and writes the name of the mountpoint to a
fifo.

The snap's `auto-install` simple daemon communicates over the snapd socket
`/run/snapd.socket` using its REST API to acknowledge the assertions, install
the snaps, and track latest/stable for each (assertion,snap) pair found on the
mounted device.

Sideloading asserted snaps (as we are doing) does not in itself configure snapd
on the system to follow any particular channel (for example, stable). If a
channel is not set, snapd defaults to stable, though we still explicitly set it
to stable.

**Note**: The current implementation assumes that stable is the correct
channel to follow. The implementation could be modified to also check a file on
USB that indicates which channel to follow for each snap.

**Note**: The current implementation assumes that the assertion and snap files
found on the drive are of the correct kind. The implementation could be modified
to also validate that the assertion contains some expected information and check
that the snap file is the expected one.

#### Additional security & control

With the current implementation, any insertion of a drive with snap and
assertion files is processed and validly asserted snaps are installed. This may
not be ideal since unauthorized persons could in theory have physical access to
the system and could therefore insert a USB drive to install any validly
asserted snaps. To address this, it would be possible to only take action if the
drive also contains a file for each snap that is signed by a secure/trusted key.
The snap could include the public part of the key, and this would be used to
first verify each snap with the signed file before continuing with installation.

The current implementation doesn't do any checking of files for corruption. This
could be remedied by including for example a digest file containing the unique
shasum of each snap and assertion.


## Usage notes


### When to remove the USB drive

If you have shell access to the device, you can tell when the process is
complete by checking the list of currently installed snaps.

The current implementation does not provide a notice to users when the process
has completed. It can potentially take ~20 minutes per snap, depending on how
long it takes to set the installed snaps to track latest/stable.


### Verifying the result from the USB drive

When you remove the USB drive, its `$(date -Iseconds).log` file shows the steps
taken including snaps installed and whether each was set to the stable channel.


### If the USB drive is removed too early

If you have removed the USB drive before the process is complete, you can simply
reinsert the USB drive and the process starts again. It is OK if the same
assertions and snaps are processed again: they are installed. You can also
delete the ones that succeeded previously to speed things up.


## Details


### automount-actions interfaces and services

```
dilyn@Ares:~ -> snap connections automount-actions
Interface      Plug                             Slot  Notes
mount-control  automount-actions:mntctl         -     -
snapd-control  automount-actions:snapd-control  -     -
```

**Note**: A Brand needs to configure these to auto connect for their image.
During testing they can be manually connected as usual.

**Note**: the `auto-mount` and `auto-install` daemons are set to `install-mode:
disable`; manually enable the services with `snap start --enable
automount-actions.auto-{install,mount}` or remove the `install-mode` from the
`snapcraft.yaml` for both services.


### Structure of a correct block device

Copy the snap and assertion files to some directory on a USB drive. The snaps
and assertions need not be in some specific directory, but each (assertion,snap)
pair must be in the same directory together. Ensure the disk is formatted to a
filesystem type supported by the kernel running on the target hardware. The
default filesystem is `vfat`, but the `FSTYPE` environment variable and the
`type` attribute of the `mount-control` interface can be modified in the
`snapcraft.yaml` to change the default filesystem.


#### Downloading snaps

For each snap, download the snap file and assertion file from the IoT App Store
with:

```
dilyn@Ares:~ -> snapcraft export-login ./store.auth
Enter your Ubuntu One e-mail address and password.
If you do not have an Ubuntu One account, you can create one at
https://snapcraft.io/account
Email: UBUNTU_SSO@email.com
Password:
Second-factor auth: XXXXXX
Exported login credentials to './store.auth'

These credentials must be used on Snapcraft 7.2 or greater.

dilyn@Ares:~ -> UBUNTU_STORE_ARCH=$ARCH \
    UBUNTU_STORE_AUTH_DATA_FILENAME=./store.auth \
    UBUNTU_STORE_ID=$STORE_ID \
    snap download --channel=<track>/<risk> SNAP_NAME
```

With

* `UBUNTU_STORE_ARCH` (optional) equal to the required architecture for the snap
  (defaults to the host architecture),
* `UBUNTU_STORE_ID` (optional) the ID of the IoT App Store where that snap is
  published (defaults to the store visible to the host device), and
* `store.auth` credentials file created for some Ubuntu SSO account with at
  least the Viewer role in the specified store.


### Things to note

Key functions of this snap include where a drive is mounted to, the name and
location of the fifo storing the name of the mounted block device, the type of
filesystem expected to be mounted, the mount options for that block device, as
well as the location of the log directory. These functions are controlled by an
environment variable which can be modified in the `snapcraft.yaml` and the
commented examples in that file show the default state of those variables if not
set.

Care should be taken to make sure the `mount-control` interface `mntctl` is
updated to match those environment variables if they are changed.
