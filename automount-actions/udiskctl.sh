#!/bin/sh -e

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: You need to run udisksctl as root!"
    exit 1
fi

exec $SNAP/usr/bin/udisksctl $@
