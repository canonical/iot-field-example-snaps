#!/bin/bash
# Show current status of all components

echo "=== SNAP INFO ==="
echo "Version: $SNAP_VERSION"
echo "Revision: $SNAP_REVISION"

echo ""
echo "=== CONFIGURATION ==="
echo "firmware-fail:  $(snapctl get firmware-fail)"
echo "firmware-delay: $(snapctl get firmware-delay) seconds"
echo "database-fail:  $(snapctl get database-fail)"
echo "webui-fail:     $(snapctl get webui-fail)"

echo ""
echo "=== DATABASE STATUS ==="
if [ -f "$SNAP_COMMON/database.ready" ]; then
    echo "Database: READY (marker file exists)"
else
    echo "Database: NOT READY (no marker file)"
fi

echo ""
echo "=== RECENT LOGS ==="
echo "--- Firmware (last 5 lines) ---"
tail -5 "$SNAP_COMMON/firmware.log" 2>/dev/null || echo "(no log)"
echo ""
echo "--- Database (last 3 lines) ---"
tail -3 "$SNAP_COMMON/database.log" 2>/dev/null || echo "(no log)"
echo ""
echo "--- Web UI (last 3 lines) ---"
tail -3 "$SNAP_COMMON/webui.log" 2>/dev/null || echo "(no log)"
