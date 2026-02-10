#!/bin/bash
# Simple daemon - runs continuously
# This tests: Does a failing service trigger rollback?

LOG_FILE="$SNAP_COMMON/service.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')

echo "[$TIMESTAMP] ========== SERVICE STARTED ==========" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_VERSION=$SNAP_VERSION" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_REVISION=$SNAP_REVISION" >> "$LOG_FILE"
echo "[$TIMESTAMP] PID=$$" >> "$LOG_FILE"

# Check if configured to fail on startup
SERVICE_FAIL=$(snapctl get service-fail)
echo "[$TIMESTAMP] service-fail config: '$SERVICE_FAIL'" >> "$LOG_FILE"

if [ "$SERVICE_FAIL" = "true" ]; then
    echo "[$TIMESTAMP] SERVICE FAILING AS CONFIGURED" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Exiting with code 1" >> "$LOG_FILE"
    exit 1
fi

# Keep running and log periodically
echo "[$TIMESTAMP] Service running normally" >> "$LOG_FILE"
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "[$TIMESTAMP] heartbeat" >> "$LOG_FILE"
    sleep 30
done
