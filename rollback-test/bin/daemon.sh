#!/bin/bash
# Oneshot daemon - runs once at startup

LOG_FILE="$SNAP_COMMON/daemon.log"

echo "$(date): Oneshot daemon started" >> "$LOG_FILE"
echo "$(date): SNAP_VERSION=$SNAP_VERSION" >> "$LOG_FILE"
echo "$(date): SNAP_REVISION=$SNAP_REVISION" >> "$LOG_FILE"

# Check if configured to fail
SERVICE_FAIL=$(snapctl get service-fail)
if [ "$SERVICE_FAIL" = "true" ]; then
    echo "$(date): Configured to fail - exiting with error" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): Oneshot daemon completed successfully" >> "$LOG_FILE"
exit 0
