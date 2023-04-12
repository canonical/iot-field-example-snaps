. "${TESTDIR}/common"

. "${SNAP}/bin/auto-install"

add_test find_assertions_test
find_assertions_test() {
    enable_testdata
    enable_snap_common
    enable_snap_data

    readonly _log_file="${_testdata}/log"

    for _i in $(seq 5); do
        echo -n >> "${_testdata}/${_i}.assert"
        echo -n >> "${_testdata}/${_i}.snap"
    done

    ack_asserts() echo "$*"

    assert_eq \
        "$(find_assertions "$_testdata" | xargs basename -a | tr '\n' ' ')" \
        "1.assert 2.assert 3.assert 4.assert 5.assert "
}
