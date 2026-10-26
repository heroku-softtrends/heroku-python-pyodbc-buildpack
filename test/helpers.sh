#!/bin/sh
# Shared helpers for the buildpack test scripts. No external dependencies
# (no shunit2/bats/rspec) so these run anywhere /bin/sh and standard
# coreutils are available - including plain CI containers.

TESTS_RUN=0
TESTS_FAILED=0

pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "  ok - $1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "  NOT ok - $1"
}

assert_file_exists() {
  if [ -f "$1" ]; then
    pass "$2"
  else
    fail "$2 (missing file: $1)"
  fi
}

assert_dir_exists() {
  if [ -d "$1" ]; then
    pass "$2"
  else
    fail "$2 (missing directory: $1)"
  fi
}

assert_contains() {
  # assert_contains <file> <needle> <description>
  if grep -qF "$2" "$1" 2>/dev/null; then
    pass "$3"
  else
    fail "$3 (did not find '$2' in $1)"
  fi
}

assert_eq() {
  # assert_eq <actual> <expected> <description>
  if [ "$1" = "$2" ]; then
    pass "$3"
  else
    fail "$3 (expected '$2', got '$1')"
  fi
}

# Builds a fake BUILD_DIR that mimics what heroku-buildpack-apt leaves
# behind after installing an msodbcsql{17,18} .deb via an Aptfile.
# Usage: make_fake_apt_layout <build_dir> <driver_version e.g. 18>
make_fake_apt_layout() {
  build_dir=$1
  version=$2
  pkg_dir="${build_dir}/.apt/opt/microsoft/msodbcsql${version}"
  mkdir -p "${pkg_dir}/lib64"
  mkdir -p "${pkg_dir}/share/resources/en_US"
  # Minimal stand-ins for the real shared libs/resources the .deb ships.
  touch "${pkg_dir}/lib64/libmsodbcsql-${version}.0.so.1.1"
  touch "${pkg_dir}/share/resources/en_US/msodbcsqlr${version}.rll"
}

summarize() {
  echo ""
  echo "$TESTS_RUN tests, $TESTS_FAILED failed"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
  fi
  exit 0
}
