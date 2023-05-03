#!/bin/sh -e

docker-compose -f "$SNAP/usr/share/composers/nginx-compose.yml" up
