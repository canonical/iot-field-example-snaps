# Multiple snaps built out of one codebase

This is an example of how you can build multiple snaps out of a single codebase.

Generally, the `snapcraft` tool assumes that the `snapcraft.yaml` file that it takes as instructions lives under `./snap/snapcraft.yaml` like so:

```
.
└── snap
    └── snapcraft.yaml
```

Nesting it deeper can cause issues, especially when you start building in managed LXD containers or Multipass VMs. In those cases, `snapcraft` will often not copy all of the source into the build environment. Specifically

```
parts:
    my-part:
        plugin: dump
        source: ../src
```
will fail.

To work around this, we can set up a directory structure like seen here:
```
.
├── Makefile
├── README.md
├── snaps
│   ├── snap-a
│   │   └── snap
│   │       └── snapcraft.yaml
│   └── snap-b
│       └── snap
│           └── snapcraft.yaml
└── src
    ├── script-a
    └── script-b
```

with the following rules in our `Makefile`:

```
SNAPCRAFTFLAGS ?=

SNAPS = $(sort $(notdir $(wildcard ./snaps/*)))

$(SNAPS) : force-snap
	rm -f ./snap
	ln -s ./snaps/$@/snap ./snap
	snapcraft $(SNAPCRAFTFLAGS)

.PHONY: clean-snap force-snap
clean-snap:
	snapcraft clean $(SNAPCRAFTFLAGS)

force-snap:
```

Then, to build snaps, we can run the following, or another similar variation:

```
$ make snap-a

$ make snap-b

$ make snap-a SNAPCRAFTFLAGS=--use-lxd
```

As an alternative to `SNAPCRAFTFLAGS` the [`SNAPCRAFT_BUILD_ENVIRONMENT` environment variable](https://snapcraft.io/docs/build-options) will also be respected as normal.
