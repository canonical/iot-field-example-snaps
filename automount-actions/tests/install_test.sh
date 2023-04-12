. "${TESTDIR}/common"

. "${SNAP}/bin/auto-install"

add_test find_assertions_test
find_assertions_test() {
    enable_testdata
    enable_snap_common
    enable_snap_data

    readonly _log_file="${_testdata}/log"

    _files="1:2:3:hello world"

    (
        IFS=:
        for _file in $_files; do
            echo -n >> "${_testdata}/${_file}.assert"
            echo -n >> "${_testdata}/${_file}.snap"
        done
    )

    # Override the ack_asserts() call in find_assertions
    ack_asserts() {
        while [ "$#" -ne 0 ]; do
            echo "$1"
            shift
        done
    }

    _asserts="$(echo "$_files" | sed 's/:/.assert\n/g').assert"

    assert_eq \
        "$(find_assertions "$_testdata" | xargs -IARG basename "ARG")" \
        "$_asserts"
}
