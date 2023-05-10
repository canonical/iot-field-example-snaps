#!/bin/sh -e

docker run --name=tocker-nginx \
    -v "$SNAP/usr/share/composers/compositions:/usr/share/nginx/html" \
    nginx:latest
