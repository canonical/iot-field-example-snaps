#!/bin/bash
# View all logs

echo "=== HOOKS LOG ==="
cat "$SNAP_COMMON/hooks.log" 2>/dev/null || echo "(no log)"

echo ""
echo "=== FIRMWARE LOG ==="
cat "$SNAP_COMMON/firmware.log" 2>/dev/null || echo "(no log)"

echo ""
echo "=== DATABASE LOG ==="
cat "$SNAP_COMMON/database.log" 2>/dev/null || echo "(no log)"

echo ""
echo "=== WEB UI LOG ==="
cat "$SNAP_COMMON/webui.log" 2>/dev/null || echo "(no log)"
