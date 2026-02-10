#!/bin/bash
# Helper to configure failure scenarios

case "$1" in
    firmware)
        snapctl set firmware-fail=true
        echo "Set firmware-fail=true (oneshot will fail -> ROLLBACK)"
        ;;
    firmware-timeout)
        # Set a long delay to test timeout behavior
        snapctl set firmware-delay="${2:-120}"
        echo "Set firmware-delay=${2:-120} seconds (test timeout)"
        ;;
    database)
        snapctl set database-fail=true
        echo "Set database-fail=true (NO rollback, service restarts)"
        ;;
    webui)
        snapctl set webui-fail=true
        echo "Set webui-fail=true (NO rollback, service restarts)"
        ;;
    reset|clear)
        snapctl set firmware-fail=false
        snapctl set firmware-delay=5
        snapctl set database-fail=false
        snapctl set webui-fail=false
        # Clean up marker file
        rm -f "$SNAP_COMMON/database.ready"
        echo "All settings reset to defaults"
        ;;
    status)
        echo "Current configuration:"
        echo "  firmware-fail:  $(snapctl get firmware-fail)"
        echo "  firmware-delay: $(snapctl get firmware-delay) seconds"
        echo "  database-fail:  $(snapctl get database-fail)"
        echo "  webui-fail:     $(snapctl get webui-fail)"
        ;;
    *)
        echo "Usage: rollback-test.trigger-fail <scenario>"
        echo ""
        echo "Scenarios:"
        echo "  firmware          - Fail firmware update (TRIGGERS ROLLBACK)"
        echo "  firmware-timeout [sec] - Set firmware delay (test timeout)"
        echo "  database          - Fail database (NO rollback)"
        echo "  webui             - Fail web UI (NO rollback)"
        echo "  reset             - Clear all failure flags"
        echo "  status            - Show current config"
        echo ""
        echo "Key insight:"
        echo "  - Oneshot (firmware) failure -> ROLLBACK"
        echo "  - Simple daemon failure -> NO rollback (just restarts)"
        ;;
esac
