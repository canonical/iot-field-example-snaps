#!/bin/sh

# mklog ensures that a log file exists
mklog() {
    # FIXME: if mklog() is called within a subshell,
    #        then LOG_DIR isn't getting globally updated
    _log_dir="${1:-"${LOG_DIR:="$(mktemp -d)"}"}"

    [ -d "$_log_dir" ] || mkdir -p "$_log_dir"

    # TODO: _log_path points to a .log file. This variable seems misnamed
    _log_path="${_log_dir}/$(date -Iseconds).log"
    : >| "$_log_path" && echo "$_log_path"
}

# log to SNAP_COMMON and TTY
# _log_file is created by auto-install.sh and will exist
# shellcheck disable=2154
log() {
    printf '%s %s\n' \
        "$(date -Iseconds)" "$*" | tee -a "${_log_file}" >&2
}

# rest_call submits either an acknowledge, install, or channel track request to
# the snapd socket. For more information on valid endpoints, see:
# https://snapcraft.io/docs/snapd-api
rest_call() {
    _action="$1"
    _file="$2"

    _snap_name="$(basename "${2%%_*}")"
    _socket="${SNAPD_SOCKET:-/run/snapd.socket}"

    case "$_action" in
        ack)
            curl \
                -sS \
                -X POST \
                --data-binary "@$_file" \
                --unix-socket "$_socket" \
                http://localhost/v2/assertions
        ;;
        install)
            curl \
                -sS \
                -X POST \
                --form snap="@$_file" \
                --unix-socket "$_socket" \
                http://localhost/v2/snaps
        ;;
        track)
            curl \
                -sS \
                -X POST \
                --unix-socket "$_socket" \
                --header "Content-Type: application/json" \
                --data '{"action":"switch","channel":"stable"}' \
                "http://localhost/v2/snaps/${_snap_name}"
        ;;
    esac
}

# ack_assert acknowledges an assertion file
# ack_assert does not verify if the assertion type is of a valid kind
ack_assert() {
    _assert="$1"

    # TODO: check that the provided assertion meets the minimum requirements to
    # be a valid assertion accompanying a snap. It is expected that a valid
    # assertion file has an account-key, snap-declaration, and snap-revision
    # https://ubuntu.com/core/docs/reference/assertions/account-key
    # https://ubuntu.com/core/docs/reference/assertions/snap-declaration
    # https://ubuntu.com/core/docs/reference/assertions/snap-revision

    # Ack the assert
    _response="$(rest_call ack "$_assert")"

    if ! echo "$_response" | grep -Iq '"status":"OK"'; then
        log "ERROR: ACKNOWLEDGE RESULT: $_assert not acknowledged"
        return 1
    fi

    log "ACKNOWLEDGE RESULT: $_assert acknowledged"
}

# install_snap installs a snap file
# install_snap does not verify if the snap file is of a valid kind
install_snap() {
    _snap="$1"

    # TODO: check that the provided snap meets the minimum requirements to be a
    # valid snap file. There is no magic number associated with either a
    # SquashFS or a snap, and the low-hanging fruit for verification are
    # relatively weak. For instance, we can verify that the size of the file
    # matches the size listed in the corresponding assertion
    # Theoretically there is no harm that can be done if the snap file is
    # invalid; snapd will ensure it matches the corresponding assertion and if
    # it doesn't, won't install it

    # install the snap
    _response="$(rest_call install "$_snap")"

    if ! echo "$_response" | grep -Iq '"status":"Accepted"'; then
        log "ERROR: INSTALL RESULT: ${_snap##*/} not installed"
        return 1
    fi

    log "INSTALL RESULT: ${_snap##*/} installed"
}

# track_stable sets the upstream tracking channel for a snap
# track_stable can optionally fail and will require manual intervention
track_stable() {
    # Keep trying to set the channel to stable because it may take some
    #   time if a snap change is in progress. Quadratically back off each loop,
    #   and quit after 9 loops, for a sum total of ~17 minutes

    _snap_name="$1"

    _loop_count=0
    _sleep=2

    while
        _response="$(rest_call track "$_snap_name")"

        if echo "$_response" | grep -Iq '"status":"Accepted"'; then
            log "${_snap_name} is now following stable"
            return 0
        fi

        [ $_loop_count -lt 9 ]
    do
        sleep $_sleep

        : $(( _loop_count += 1 ))
        : $(( _sleep      *= 2 ))
    done

    log "WARN: failed to make $_snap_name follow stable"
    log "WARN: Manual intervention may be required for $_snap_name to refresh"
    return 1
}

# eject_device handles device ejection and cleaning
eject_device() {
    # Try to copy log file over
    cp -f "$_log_file" "$_mount_point" || true

    # Remove the temp directory
    rm -r "$(dirname "$_log_file")"

    sync
    umount "$_mount_point"
    rmdir "$_mount_point"
}

# process_mounts verifies that for each assertion on a disk there is a
# correspondingly named snap file in the same directory. It acknowledges the
# assertion, installs the snap, and attempts to set that snap to track
# latest/stable
process_mounts() {
    _watch_file="$1"

    while read -r _mount_point < "$_watch_file"; do

        # Make sure the mount actually exists
        [ -d "$_mount_point" ] || continue

        # TODO: investigate how to further extend or scope mklog()
        # For instance, instead of spawning a subshell we could do:
        #   mklog $_log_file
        #   :> $_log_file; readonly $_log_file
        #shellcheck disable=2119
        _log_file="$(mklog)"

        log "Mountpoint is ${_mount_point}."

        # Skip mounts that don't contain any asserts
        _asserts=$(find "$_mount_point" -name \*.assert)
        [ -n "$_asserts" ] || {
            log "WARN: No assertions found."
            eject_device
            continue
        }

        # Loop through each assert and, for those with a corresponding snap, install
        for _assert in $_asserts; do
            # Make sure a corresponding snap exists
            [ -e "${_assert%%.assert}.snap" ] || {
                log "WARN: ${_assert%%.assert}.snap not found for $_assert"
                continue
            }

            # We want to continue in cases where ack_assert and install_snap
            # succeed, but track_stable fails. track_stable is optional
            # shellcheck disable=2015
            ack_assert "$_assert" \
                && install_snap "${_assert%.assert}.snap" \
                && track_stable "$(basename "${_assert%_*}")" \
                || continue
        done

        eject_device
    done
}

# cleanup acts to make sure this daemon stays tidy
cleanup() {
    _exit_status=$?

    rm -f "$WATCH_FILE"

    # Exit with 0 if we're interrupted with INT or TERM
    case $_exit_status in 130|143) exit 0; esac
}

# main ensures our fifo exists before we proceed to operating on a disk
main() {
    # Globally set exit on error, no unset variables
    set -eu

    : "${WATCH_FILE:=/tmp/mounts.fifo}"; readonly WATCH_FILE
    [ -p "$WATCH_FILE" ] || mkfifo "$WATCH_FILE"

    trap exit    INT TERM
    trap cleanup EXIT

    process_mounts "$WATCH_FILE"
}

[ -n "$NOEXEC" ] || main
