#!/bin/bash
# SIMPLE DAEMON: Web UI service
# Depends on database - checks if database is ready
# Failure here does NOT trigger rollback

LOG_FILE="$SNAP_COMMON/webui.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')

echo "[$TIMESTAMP] ========== WEB UI STARTED ==========" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_VERSION=$SNAP_VERSION" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_REVISION=$SNAP_REVISION" >> "$LOG_FILE"

WEBUI_FAIL=$(snapctl get webui-fail)
echo "[$TIMESTAMP] webui-fail: '$WEBUI_FAIL'" >> "$LOG_FILE"

# Check if database is ready
if [ ! -f "$SNAP_COMMON/database.ready" ]; then
    echo "[$TIMESTAMP] ERROR: Database not ready (no marker file)" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Web UI cannot start without database" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Note: This does NOT trigger rollback" >> "$LOG_FILE"
    exit 1
fi

if [ "$WEBUI_FAIL" = "true" ]; then
    echo "[$TIMESTAMP] WEB UI FAILING AS CONFIGURED" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Note: This does NOT trigger rollback" >> "$LOG_FILE"
    exit 1
fi

echo "[$TIMESTAMP] Web UI connected to database successfully" >> "$LOG_FILE"

# Keep running
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "[$TIMESTAMP] webui heartbeat" >> "$LOG_FILE"
    sleep 30
done
