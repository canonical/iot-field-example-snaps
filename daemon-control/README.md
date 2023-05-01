# Managing Daemon Startup

_Canonical Devices and IoT, Field Engineering_


Version 1.3

## Introduction

This document presents an approach through which one snap can control startup of
daemons in the same snap and in other snaps so that simple daemons on an Ubuntu
Core system can be managed effectively through system boot and restart,
including unclean restarts such as from power cutoff and restore.


## Requirements

* One snap service (Controller) to start other services (Controlled) in the same
  snap and in other snaps

* Controlled services must not start until Controller so directs

* Controller and Controlled services must auto restart

* System must function as expected through system restart, even in unclean restart


## Considerations

* One snap controlling daemons in another snap is on the current cycle
  Snapcraft Roadmap, but has not landed. But, we can use [snapd-control
  interface](https://snapcraft.io/docs/snapd-control-interface)
  ([source](https://github.com/snapcore/snapd/blob/416ae3a0091532fcc5220d1d222f28347c47b570/interfaces/builtin/snapd_control.go))
  and the [snapd REST API](https://forum.snapcraft.io/t/snapd-rest-api/17954)
  to start daemons in other snaps
    * `snapd-control` is a very powerful interface whose use should be limited, so
      the recommendation is to declare it as a plug only in the daemon/app that
      requires it, not snap wide, unless that is required.
    * `snapd-control` interface does not auto connect by default. Auto connection
      for Brands can be requested through the Brand’s Support portal.
* simple daemons by default auto start on every boot, which we don’t want.
    * Either disable them in the `install` hook (as in the Controlled snap) or
      use the `install-mode: disable` flag in the `snapcraft.yaml`, to start
      them via `snapctl` or the snapd REST API.
    * A snap daemon has two statuses, Startup and Current:

```
      knitzsche@bionic:~$ snap services test-controlled-daemons
      Service                               Startup   Current  Notes
      test-controlled-daemons.controlled-1  disabled  inactive   -
```

    * Starting such a daemon makes it active, and if declared as simple, it
      restarts if it dies or is killed.
    * Even if started, the Startup remains disabled, meaning on system
      start/restart, the daemon does not auto start.


## Design

* The Controller and Controlled daemons must auto restart, so they are declared
  as simple
* The Controlled daemons must not start up on boot. This can be done with an
  install hook that uses `snapctl` to disable all Controlled daemons or by
  setting `install-mode: disable`
    * The snap's source tree needs a `snap/meta/hooks/install` hook script that
      includes something like this, for each daemon in the snap to be disabled:

```
      #!/bin/sh -e
      snapctl stop test-controlled-daemons.controlled-1 --disable
```

* Starting a Controlled daemon programmatically (but not enabling it)
    * When the daemon that is to be started (or stopped) is in the same snap as
      the Controller snap, you can use the `snapctl` command (or the snapd REST
      API):

```
      #/bin/sh -e
      snapctl start test-controlled-daemons.controlled-1
```

* When the daemon to be started (or stopped) is in a different snap than the
  Controller, `snapctl` cannot be used; you must use the snapd REST API, which as
  noted requires the `snapd-control` interface plug declared in the Controller and
  connected (manually at runtime or automatically through the Brand Store).
    * See sample code for implementing the snapd REST API calls in Golang.


## Sample Code


### Controlled snap

[Source](https://github.com/canonical/iot-field-example-snaps/tree/main/daemon-control/controlled-daemon)

This snap has a simple daemon `controlled-1` that loops forever and outputs a
message every 5 seconds that displays in the journal:

```
knitzsche@bionic:~$ sudo -S journalctl -f
Feb 20 16:51:16 bionic test-controlled-daemons.controlled-1[4544]: test-controlled-daemons.controlled-1 is running
Feb 20 16:51:21 bionic test-controlled-daemons.controlled-1[4544]: test-controlled-daemons.controlled-1 is running
```

However, the daemon [is disabled on install by the `install`
hook](https://github.com/canonical/iot-field-example-snaps/blob/main/daemon-control/controlled-daemon/snap/hooks/install),
so it never auto starts on bootup:

The snap also has an named `start-controlled-1` to start it, and an app named
`stop-controlled-1` to stop it

These apps use `snapctl start|stop SNAP.DAEMON` to start and stop the daemon.
(As noted, this can also be done through the snapd REST API.)


### Controller snap

[Source](https://github.com/canonical/iot-field-example-snaps/tree/main/daemon-control/controller-daemon)

This snap is very similar to the Controlled snap. It has a simple daemon
`controlled-1` that is disabled on install by the `install` hook script.  It
also has start and stop commands for that daemon.

But, this snap also has a daemon `controller` that loops and every 30 seconds
performs two snapd REST API calls to start both daemons:

* The daemon in the other snap: `test-controlled-daemons.controlled-1`

* The daemon in the this snap: `test-controller-daemons.controlled-1`

This snap also has a list command that calls the snapd REST API and outputs a
rudimentary list of installed snaps.

```
root@bionic:~# test-controller-daemons.list
Snap:snapcraft, Revision: 3977
Snap:snapd, Revision: 6441
Snap:, Revision: x4
Snap:, Revision: x1
Snap:core, Revision: 8692
Snap:Core 18, Revision: 1671
Snap:Go, Revision: 5369
```


### Trying the samples

Build and install the Controlled `test-controlled-daemons` snap. (You can build
through the prime stage with `--destructive-mode` and then use `snap try prime`, or
build to a snap and install it with the `--dangerous` flag).

Check the services:

```
knitzsche@bionic:~/test-controlled-daemons$ snap services test-controlled-daemons
Service                               Startup   Current   Notes
test-controlled-daemons.controlled-1  disabled  inactive  -
```

Disabled and inactive, as expected, due to the `install` hook.

In another terminal, follow the journal. (Use `sudo` if needed):

```
root@bionic:~# journalctl -f
```

In the first terminal, start the daemon:

```
root@bionic:~# test-controlled-daemons.start-controlled-1
start-controlled-1 app running
```

The journal shows the start up and the every-five-second message indicating it is running:

```
Feb 20 18:38:49 bionic systemd[1]: Started Service for snap application test-controlled-daemons.controlled-1.
Feb 20 18:38:49 bionic test-controlled-daemons.controlled-1[14811]: test-controlled-daemons.controlled-1 is running
Feb 20 18:38:54 bionic test-controlled-daemons.controlled-1[14811]: test-controlled-daemons.controlled-1 is running
```

Stop the daemon (because we want to test the Controller starting it next):

```
root@bionic:~# test-controlled-daemons.stop-controlled-1
stop-controlled-1 app running
```

Build and install the Controller `test-controller-daemons` snap.

Check its services:

```
knitzsche@bionic:~/test-controller-daemons$ snap services test-controller-daemons
Service                               Startup   Current   Notes
test-controller-daemons.controlled-1  disabled  inactive  -
test-controller-daemons.controller    enabled   active    -
```

As expected:
The `controlled-1` daemon is inactive due to it being disabled in the `install` hook.
The `controller` daemon is enabled and active.

But, the `controller` daemon cannot yet succeed since it requires the
`snapd-control` interface to be connected in order to get access to the snapd REST
API.

Check out this snap’s connections:

```
knitzsche@bionic:~/test-controller-daemons$ snap connections test-controller-daemons
Interface      Plug                                   Slot  Notes
snapd-control  test-controller-daemons:snapd-control  -     -
```

Now connect it, and keep an eye on the followed journal in the other terminal:

```
$ snap connect test-controller-daemons:snapd-control :snapd-control
```

Journal output:

```
Feb 20 18:49:05 bionic test-controller-daemons.controller[15446]: About to start test-controller-daemons.controlled-1
Feb 20 18:49:05 bionic test-controller-daemons.controller[15446]: cannot communicate with server: Post http://localhost/v2/apps: dial unix /run/snapd.socket: connect: permission denied < before snapd-control
Feb 20 18:49:25 bionic test-controller-daemons.controller[15446]: About to start test-controller-daemons.controlled-1
Feb 20 18:49:26 bionic test-controller-daemons.controller[15446]: Change ID :513
Feb 20 18:49:26 bionic test-controller-daemons.controller[15446]: About to start test-controller-daemons.controlled-1
Feb 20 18:49:26 bionic systemd[1]: Started Service for snap application test-controller-daemons.controlled-1.
Feb 20 18:49:26 bionic test-controller-daemons.controlled-1[15599]: test-controller-daemons.controlled-1 is running
Feb 20 18:49:27 bionic test-controller-daemons.controller[15446]: Change ID :514
Feb 20 18:49:27 bionic systemd[1]: Started Service for snap application test-controlled-daemons.controlled-1.
Feb 20 18:49:27 bionic test-controlled-daemons.controlled-1[15629]: test-controlled-daemons.controlled-1 is running
Feb 20 18:49:31 bionic test-controller-daemons.controlled-1[15599]: test-controller-daemons.controlled-1 is running
Feb 20 18:49:32 bionic test-controlled-daemons.controlled-1[15629]: test-controlled-daemons.controlled-1 is running
Feb 20 18:49:36 bionic test-controller-daemons.controlled-1[15599]: test-controller-daemons.controlled-1 is running
```

We see that both daemons, one in Controller snap and one in Controlled snap are
running.
