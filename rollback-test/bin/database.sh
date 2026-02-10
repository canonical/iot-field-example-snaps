#!/bin/bash
# SIMPLE DAEMON: Database service
# Failure here does NOT trigger rollback

LOG_FILE="$SNAP_COMMON/database.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')

echo "[$TIMESTAMP] ========== DATABASE STARTED ==========" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_VERSION=$SNAP_VERSION" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_REVISION=$SNAP_REVISION" >> "$LOG_FILE"

DATABASE_FAIL=$(snapctl get database-fail)
echo "[$TIMESTAMP] database-fail: '$DATABASE_FAIL'" >> "$LOG_FILE"

if [ "$DATABASE_FAIL" = "true" ]; then
    echo "[$TIMESTAMP] DATABASE FAILING AS CONFIGURED" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Note: This does NOT trigger rollback" >> "$LOG_FILE"
    exit 1
fi

# Create a "ready" marker file for webui to check
touch "$SNAP_COMMON/database.ready"
echo "[$TIMESTAMP] Database ready (marker file created)" >> "$LOG_FILE"

# Keep running
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "[$TIMESTAMP] database heartbeat" >> "$LOG_FILE"
    sleep 30
done
