#!/usr/bin/env bats

setup() {
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=$(mktemp -d -t testphpdebugger-XXXXXX)
  export PROJNAME="test-php-debugger-$(basename "$TESTDIR")"
  export DDEV_NON_INTERACTIVE=true

  cd "$TESTDIR"
  ddev config --project-name="$PROJNAME" --project-type=php --php-version=8.4
  ddev start -y
}

teardown() {
  cd "$TESTDIR" || true
  ddev delete -Oy "$PROJNAME" || true
  rm -rf "$TESTDIR"
}

@test "install addon and verify php-debugger replaces xdebug" {
  cd "$TESTDIR"
  ddev add-on get "$DIR"
  ddev restart

  # Enable xdebug (which now loads php-debugger)
  ddev xdebug on

  # php -v should mention "PHP Debugger"
  run ddev exec php -v
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PHP Debugger"* ]]

  # extension_loaded('xdebug') should return true (drop-in compatible)
  run ddev exec php -r 'echo extension_loaded("xdebug") ? "LOADED" : "NOT_LOADED";'
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOADED"* ]]
}

@test "ddev xdebug off disables php-debugger" {
  cd "$TESTDIR"
  ddev add-on get "$DIR"
  ddev restart

  ddev xdebug on
  ddev xdebug off

  # php -v should NOT mention "PHP Debugger"
  run ddev exec php -v
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" != *"PHP Debugger"* ]]
}

@test "original xdebug.so is backed up" {
  cd "$TESTDIR"
  ddev add-on get "$DIR"
  ddev restart

  run ddev exec find /usr/lib/php -name "xdebug.so.original"
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"xdebug.so.original"* ]]
}
