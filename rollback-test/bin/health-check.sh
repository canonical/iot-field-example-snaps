#!/bin/bash
# Health check script

LOG_FILE="$SNAP_COMMON/health.log"

echo "$(date): Health check running" >> "$LOG_FILE"

# Check if configured to fail
HEALTH_FAIL=$(snapctl get health-fail)
if [ "$HEALTH_FAIL" = "true" ]; then
    echo "$(date): Health check FAILED (configured)" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): Health check PASSED" >> "$LOG_FILE"
exit 0
