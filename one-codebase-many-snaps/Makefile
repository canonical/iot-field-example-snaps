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
