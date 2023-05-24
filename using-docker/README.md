# Using Docker from a snap

This snap provides examples of how docker workloads can be deployed on Ubuntu
Core by utilizing the docker commands, compose-files, and other artifacts to
manage the lifecycle of one or more docker workloads.

It requires the Docker snap. After recent changes, the Docker snap requires
`snapd` 2.59.1. If an older version of `snapd` is required, please use the Docker
snap available on 18/stable.


**REMEMBER**: the [docker interface](https://github.com/snapcore/snapd/blob/cdf2a1577ac7b8f98b1201b0ae5fd8f3b3d10a52/interfaces/builtin/docker_support.go#L59-L63)
is potentially HIGHLY dangerous. It is a very permissive interface and great
caution should be used before deploying the Docker snap in production. It is
recommended to migrate from using Docker containers to placing applications
within snaps directly.


## Overview

This snap showcases several things:

1) interacting directly with Docker through a wrapper at the CLI
2) creating e.g. a web server by using a daemon from a Docker compose file
3) leverage volumes to share content between containers
4) host an elaborate system such as EdgeX
5) Pre-seeding Docker images to create containers at install- or run-time
6) communicate over the Docker socket via its REST API


### The apps

All apps are scripts available in `$SNAP/usr/bin` in the built snap and viewable
here in [`src/usr/bin`](src/usr/bin).

Each app declares an environment and a set of plugs. The environment defines the
location of the Docker executables and the relevant python libraries and the
plugs are one of `docker` or `docker-executables` depending on if we need *only* the
Docker socket or if we also need the various other executables and libraries.

Most if not all of the following apps could be improved to make them more
resilient or feature-rich. These additions are use-case dependent, the intention
of this snap is to a show a minimum-viable collection of tools and examples.

#### `tocker`

A trivial example; literally just executes `docker run "$@"`, with `$@` being
the arguments given to `tocker` at the CLI.


#### `ticker`

A very rudimentary daemon which stands up an nginx container using
`docker compose` using the corresponding
`$SNAP/usr/share/composers/nginx-compose.yml` file.


#### `nginx-volume`

Demonstrates a synthesis between the `ticker` app's daemon functionality and the
`jenkins{1,2}` apps' volume sharing.


#### `jenkins{1,2}`

Two Docker containers are created which declare a specific volume in order to
share relevant files and configuration.


#### `edgex`

Creates whatever containers are defined in the downloaded EdgeX compose file
(downloaded at build-time).


#### `rest`

Includes four simple REST calls which are sent directly to the Docker socket
instead of through the usual Docker commands. See
[here](https://docs.docker.com/engine/api/) for more information on the Docker
REST API.


### The parts


#### copy-src

Dumps all of the relevant source files used by our various apps into the snap.
In general, compose files and content go in `src/usr/share/composers`, while
scripts or other binaries go in `src/usr/bin`.


#### edgex

Fetches a specific compose file from the [EdgeX Foundry
GitHub](https://github.com/edgexfoundry). It also does some light editing on
this compose file to work around a known Apparmor limitation.


#### seed-image

Uses `docker` on the build machine to download various container images at
build-time to then create on the target machine at run- or install-time. Note
that these containers could also be pre-downloaded and added to the `images/`
directory.


#### rest-api

Simply stages a run-time dependency. This could be removed with the
`stage-package` added to another part.


### The plugs and hooks

The snap defines an attribute on the `docker-executables` content interface, the
slot side of which is provided by the Docker snap itself. It uses the
`default-provider` option to ensure that Docker is installed on the device.

A commented out `personal-files` interface is also included, but should only be
used as a last resort in cases where the `--config` flag or `DOCKER_CONFIG`
environment variable cannot be used.

The hooks, both `configure` and `connect-plug-docker`, will spin up any
containers corresponding to the images pre-seeded into the snap at build-time.
These hooks require their own declaration of the `docker` and
`docker-executables` interfaces because of this.


## Usage

If you wish to pre-seed the snap with Docker container images, download them and
add them to an `images/` directory in the root of this project directory with
the `.docker` suffix:

```
docker pull $example
docker save -o images/example.docker example
```

The snap can be built by simply issuing `snapcraft`.

Install the snap and connect the required interfaces:

```
snap install --dangerous tocker_*.snap
snap connect tocker:docker-executables docker:docker-executables
snap connect tocker:docker             docker:docker-daemon
```

Autoconnections for these interfaces can be managed via the [Store dashboard
UI](dashboard.snapcraft.io) and in the case of the super-privileged docker
interface, requested via a support ticket.
