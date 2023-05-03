#!/bin/sh -e

docker-compose -f "$SNAP/usr/share/composers/edgex-compose.yml" up
