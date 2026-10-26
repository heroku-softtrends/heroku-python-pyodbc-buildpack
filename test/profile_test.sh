#!/bin/bash
# Tests for .profile.d/configure-odbc.sh - the script that runs on every
# dyno boot to write odbc.ini/odbcinst.ini pointing at the driver that
# bin/compile copied into .apt/usr/lib.
#
# This file must run under bash, not plain /bin/sh (which may be dash):
# configure-odbc.sh uses bash-only syntax ([[ ]]), and that's how Heroku
# actually sources .profile.d/*.sh at dyno boot, so the test should match.
#
# Run from the repo root:
#   bash test/profile_test.sh

set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/helpers.sh"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "== configure-odbc.sh (simulated dyno boot, driver 18) =="

# On a real dyno, $HOME (/app) *is* the slug that bin/compile built.
# bin/compile already pre-creates .apt/usr/lib/odbc/conf/ at build time,
# and configure-odbc.sh also mkdir -p's it itself at boot as a safety net.
# The faithful way to test the runtime script is to run bin/compile first
# and then source configure-odbc.sh with HOME pointed at that same build
# dir, exactly as Heroku's dyno boot would.
FAKE_HOME="${WORK_DIR}/home"
mkdir -p "$FAKE_HOME"
make_fake_apt_layout "$FAKE_HOME" 18
"${REPO_DIR}/bin/compile" "$FAKE_HOME" >/dev/null 2>&1

# .profile.d scripts are sourced, with $HOME already set, so we do the same
# here rather than exec-ing the script as a subprocess.
HOME="$FAKE_HOME"
export HOME
. "${REPO_DIR}/.profile.d/configure-odbc.sh"

assert_file_exists "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbc.ini" \
  "odbc.ini is written"
assert_file_exists "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbcinst.ini" \
  "odbcinst.ini is written"
assert_contains "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbc.ini" \
  "ODBC Driver 18 for SQL Server" \
  "odbc.ini names the correct driver version"
assert_contains "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbc.ini" \
  "Driver=/app/.apt/usr/lib/libmsodbcsql-18.0.so.1.1" \
  "odbc.ini points at the copied shared lib"
assert_contains "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbcinst.ini" \
  "Driver=/app/.apt/usr/lib/libmsodbcsql-18.0.so.1.1" \
  "odbcinst.ini points at the copied shared lib"
# ODBCINI must point at the odbc.ini *file* itself; ODBCSYSINI must point
# at the *directory* containing odbcinst.ini. Mixing these up is a common
# unixODBC gotcha - getting it backwards makes pyodbc silently fail to
# find the driver at connect time.
assert_eq "$ODBCINI" "${FAKE_HOME}/.apt/usr/lib/odbc/conf/odbc.ini" \
  "ODBCINI is exported as the odbc.ini FILE path"
assert_eq "$ODBCSYSINI" "${FAKE_HOME}/.apt/usr/lib/odbc/conf" \
  "ODBCSYSINI is exported as the conf DIRECTORY path"

echo ""
echo "== configure-odbc.sh (no driver library present) =="

# If bin/compile never ran, or the apt install failed silently, there is
# no libmsodbcsql-*.so* under .apt/usr/lib. configure-odbc.sh must detect
# that and bail out loudly instead of writing a broken odbc.ini pointing
# at a file that doesn't exist.
EMPTY_HOME="${WORK_DIR}/empty_home"
mkdir -p "${EMPTY_HOME}/.apt/usr/lib"
mkdir -p "${EMPTY_HOME}/.apt/opt/microsoft/msodbcsql18"
# .apt/usr/lib exists but has no driver .so in it (e.g. a stray file).
touch "${EMPTY_HOME}/.apt/usr/lib/README"

HOME="$EMPTY_HOME"
export HOME
ERROR_OUTPUT=$(. "${REPO_DIR}/.profile.d/configure-odbc.sh" 2>&1)
ERROR_STATUS=$?

assert_eq "$ERROR_STATUS" "1" \
  "configure-odbc.sh returns non-zero when no driver library is found"
case "$ERROR_OUTPUT" in
  *"Microsoft ODBC driver library not found"*)
    pass "configure-odbc.sh prints a clear error when no driver library is found" ;;
  *)
    fail "configure-odbc.sh prints a clear error when no driver library is found (got: $ERROR_OUTPUT)" ;;
esac
if [ -f "${EMPTY_HOME}/.apt/usr/lib/odbc/conf/odbc.ini" ]; then
  fail "configure-odbc.sh does not write odbc.ini when no driver library is found"
else
  pass "configure-odbc.sh does not write odbc.ini when no driver library is found"
fi

summarize
