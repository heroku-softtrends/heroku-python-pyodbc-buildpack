#!/bin/sh
# Tests for bin/detect and bin/compile.
#
# Run from the repo root:
#   sh test/compile_test.sh
#
# These tests don't talk to Heroku or apt at all. They build a fake
# BUILD_DIR that looks like what heroku-buildpack-apt leaves behind after
# installing an msodbcsql{17,18} .deb, run bin/compile against it, and
# assert the files bin/compile is supposed to produce actually show up.

set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/helpers.sh"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "== bin/detect =="
DETECT_OUTPUT=$("${REPO_DIR}/bin/detect" "$WORK_DIR")
DETECT_STATUS=$?
assert_eq "$DETECT_STATUS" "0" "bin/detect exits 0"
assert_eq "$DETECT_OUTPUT" "odbc" "bin/detect prints 'odbc'"

echo ""
echo "== bin/compile with ODBC Driver 18 =="
BUILD18="${WORK_DIR}/build18"
mkdir -p "$BUILD18"
make_fake_apt_layout "$BUILD18" 18
"${REPO_DIR}/bin/compile" "$BUILD18" >/dev/null 2>&1
COMPILE18_STATUS=$?
assert_eq "$COMPILE18_STATUS" "0" "bin/compile exits 0 for driver 18"
assert_file_exists "${BUILD18}/.apt/usr/lib/libmsodbcsql-18.0.so.1.1" \
  "driver 18 shared lib copied into .apt/usr/lib"
assert_file_exists "${BUILD18}/.apt/usr/share/resources/en_US/msodbcsqlr18.rll" \
  "driver 18 resource file copied into .apt/usr/share/resources/en_US"
assert_file_exists "${BUILD18}/.profile.d/configure-odbc.sh" \
  "configure-odbc.sh copied into .profile.d"

echo ""
echo "== bin/compile with ODBC Driver 17 =="
BUILD17="${WORK_DIR}/build17"
mkdir -p "$BUILD17"
make_fake_apt_layout "$BUILD17" 17
"${REPO_DIR}/bin/compile" "$BUILD17" >/dev/null 2>&1
COMPILE17_STATUS=$?
assert_eq "$COMPILE17_STATUS" "0" "bin/compile exits 0 for driver 17"
assert_file_exists "${BUILD17}/.apt/usr/lib/libmsodbcsql-17.0.so.1.1" \
  "driver 17 shared lib copied into .apt/usr/lib"
assert_file_exists "${BUILD17}/.apt/usr/share/resources/en_US/msodbcsqlr17.rll" \
  "driver 17 resource file copied into .apt/usr/share/resources/en_US"

echo ""
echo "== bin/compile fails loudly on an incomplete install =="

# No .apt/opt/microsoft/* at all - e.g. the Aptfile is missing the
# msodbcsql .deb entry, or heroku-buildpack-apt didn't run first.
BUILD_NO_DRIVER="${WORK_DIR}/build_no_driver"
mkdir -p "$BUILD_NO_DRIVER"
OUTPUT_NO_DRIVER=$("${REPO_DIR}/bin/compile" "$BUILD_NO_DRIVER" 2>&1)
STATUS_NO_DRIVER=$?
assert_eq "$STATUS_NO_DRIVER" "1" \
  "bin/compile exits non-zero when no msodbcsql17/18 directory exists"
case "$OUTPUT_NO_DRIVER" in
  *"No msodbcsql17 or msodbcsql18 directory found"*)
    pass "bin/compile explains the missing driver directory" ;;
  *)
    fail "bin/compile explains the missing driver directory (got: $OUTPUT_NO_DRIVER)" ;;
esac

# .apt/opt/microsoft/msodbcsql18 exists but lib64/ is missing - a
# truncated or corrupted package extraction.
BUILD_NO_LIB64="${WORK_DIR}/build_no_lib64"
mkdir -p "${BUILD_NO_LIB64}/.apt/opt/microsoft/msodbcsql18/share/resources/en_US"
touch "${BUILD_NO_LIB64}/.apt/opt/microsoft/msodbcsql18/share/resources/en_US/msodbcsqlr18.rll"
OUTPUT_NO_LIB64=$("${REPO_DIR}/bin/compile" "$BUILD_NO_LIB64" 2>&1)
STATUS_NO_LIB64=$?
assert_eq "$STATUS_NO_LIB64" "1" \
  "bin/compile exits non-zero when lib64/ is missing"
case "$OUTPUT_NO_LIB64" in
  *"lib64 is missing"*)
    pass "bin/compile explains the missing lib64 directory" ;;
  *)
    fail "bin/compile explains the missing lib64 directory (got: $OUTPUT_NO_LIB64)" ;;
esac

# lib64/ exists but is empty - cp has nothing to copy, so the driver
# library never ends up in .apt/usr/lib even though the build "succeeded".
BUILD_EMPTY_LIB64="${WORK_DIR}/build_empty_lib64"
mkdir -p "${BUILD_EMPTY_LIB64}/.apt/opt/microsoft/msodbcsql18/lib64"
mkdir -p "${BUILD_EMPTY_LIB64}/.apt/opt/microsoft/msodbcsql18/share/resources/en_US"
touch "${BUILD_EMPTY_LIB64}/.apt/opt/microsoft/msodbcsql18/share/resources/en_US/msodbcsqlr18.rll"
OUTPUT_EMPTY_LIB64=$("${REPO_DIR}/bin/compile" "$BUILD_EMPTY_LIB64" 2>&1)
STATUS_EMPTY_LIB64=$?
assert_eq "$STATUS_EMPTY_LIB64" "1" \
  "bin/compile exits non-zero when lib64/ has no driver library in it"
case "$OUTPUT_EMPTY_LIB64" in
  *"driver library was not copied"*)
    pass "bin/compile explains the missing driver library" ;;
  *)
    fail "bin/compile explains the missing driver library (got: $OUTPUT_EMPTY_LIB64)" ;;
esac

# share/resources/en_US/ exists but is missing the expected .rll file.
BUILD_NO_RLL="${WORK_DIR}/build_no_rll"
mkdir -p "${BUILD_NO_RLL}/.apt/opt/microsoft/msodbcsql18/lib64"
mkdir -p "${BUILD_NO_RLL}/.apt/opt/microsoft/msodbcsql18/share/resources/en_US"
touch "${BUILD_NO_RLL}/.apt/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.0.so.1.1"
OUTPUT_NO_RLL=$("${REPO_DIR}/bin/compile" "$BUILD_NO_RLL" 2>&1)
STATUS_NO_RLL=$?
assert_eq "$STATUS_NO_RLL" "1" \
  "bin/compile exits non-zero when the .rll resource file is missing"
case "$OUTPUT_NO_RLL" in
  *"resource file was not copied"*)
    pass "bin/compile explains the missing resource file" ;;
  *)
    fail "bin/compile explains the missing resource file (got: $OUTPUT_NO_RLL)" ;;
esac

summarize
