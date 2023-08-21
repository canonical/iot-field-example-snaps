#!/bin/sh -eu

PORT="$(snapctl get daemon.port)"

while true; do
  echo 'Hello, world!' | ncat --listen --send-only localhost "$PORT"
done
