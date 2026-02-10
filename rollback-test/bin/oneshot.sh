#!/bin/bash
# Oneshot daemon - runs once after snap start/refresh
# This tests: Does a failing oneshot trigger rollback?

LOG_FILE="$SNAP_COMMON/oneshot.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')

echo "[$TIMESTAMP] ========== ONESHOT DAEMON STARTED ==========" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_VERSION=$SNAP_VERSION" >> "$LOG_FILE"
echo "[$TIMESTAMP] SNAP_REVISION=$SNAP_REVISION" >> "$LOG_FILE"
echo "[$TIMESTAMP] PID=$$" >> "$LOG_FILE"

# Check if configured to fail
ONESHOT_FAIL=$(snapctl get oneshot-fail)
echo "[$TIMESTAMP] oneshot-fail config: '$ONESHOT_FAIL'" >> "$LOG_FILE"

if [ "$ONESHOT_FAIL" = "true" ]; then
    echo "[$TIMESTAMP] ONESHOT FAILING AS CONFIGURED" >> "$LOG_FILE"
    echo "[$TIMESTAMP] Exiting with code 1" >> "$LOG_FILE"
    exit 1
fi

echo "[$TIMESTAMP] Oneshot completed successfully" >> "$LOG_FILE"
exit 0
