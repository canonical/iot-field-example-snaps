SNAPCRAFTFLAGS ?=

SNAPS = $(sort $(notdir $(wildcard ./snaps/*)))

$(SNAPS) : force-snap
	rm -f ./snap
	ln -s ./snaps/$@/snap ./snap
	snapcraft $(SNAPCRAFTFLAGS)

.PHONY: clean-snap
clean-snap:
	snapcraft clean $(SNAPCRAFTFLAGS)

.PHONY: force-snap
force-snap:
