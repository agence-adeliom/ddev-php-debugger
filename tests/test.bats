#!/usr/bin/env bats

setup() {
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=$(mktemp -d -t testphpdebugger-XXXXXX)
  export PROJNAME="test-php-debugger-$(basename "$TESTDIR")"
  export DDEV_NON_INTERACTIVE=true

  cd "$TESTDIR"
  ddev config --project-name="$PROJNAME" --project-type=php --php-version=8.3
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

  # php-debugger registers itself as the "php_debugger" module
  run ddev exec php -r 'echo extension_loaded("php_debugger") ? "LOADED" : "NOT_LOADED";'
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [ "$output" = "LOADED" ]
}

assert_php_debugger_loaded() {
  ddev xdebug on

  run ddev exec php -v
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PHP Debugger"* ]]
}

@test "php-debugger replaces xdebug for every non-default project PHP version" {
  cd "$TESTDIR"
  ddev add-on get "$DIR"

  # The web image's default `php` is 8.4 while it builds, so other versions are the regression risk.
  for version in 8.2 8.3 8.5; do
    echo "PHP ${version}"
    ddev config --php-version="$version"
    ddev restart
    assert_php_debugger_loaded
  done
}

@test "source-build fallback targets the project PHP version and keeps preinstalled packages" {
  cd "$TESTDIR"
  ddev add-on get "$DIR"

  # Force the fallback by pointing the pre-built download at a missing asset.
  sed -i.bak 's#releases/download/#releases/download/missing-#' .ddev/web-build/Dockerfile.php-debugger
  rm .ddev/web-build/Dockerfile.php-debugger.bak
  ddev restart

  assert_php_debugger_loaded

  run ddev exec git --version
  echo "Output: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == "git version"* ]]

  # Build-only packages (not in the stock web image) are still cleaned up.
  run ddev exec dpkg -s gcc
  [ "$status" -ne 0 ]
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
