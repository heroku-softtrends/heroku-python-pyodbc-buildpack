#!/bin/sh
# Runs the full test suite for this buildpack. No dependencies beyond
# /bin/sh and coreutils - safe to run in any CI container or locally.
#
#   sh test/run_tests.sh

set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

STATUS=0

echo "### compile_test.sh ###"
sh "${SCRIPT_DIR}/compile_test.sh"
[ $? -ne 0 ] && STATUS=1

echo ""
echo "### profile_test.sh ###"
# profile_test.sh must run under bash (configure-odbc.sh uses [[ ]]).
bash "${SCRIPT_DIR}/profile_test.sh"
[ $? -ne 0 ] && STATUS=1

exit $STATUS
