# ddev-php-debugger

A DDEV addon that replaces Xdebug with [php-debugger](https://github.com/pronskiy/php-debugger) — a lightweight fork focused on step-debugging only.

Xdebug adds ~324% overhead even when loaded but inactive. php-debugger strips profiling and coverage to achieve only ~4% overhead, while remaining a drop-in replacement for step-debugging (same DBGp protocol, same `xdebug.*` INI settings).

## Requirements

- DDEV >= v1.24.0
- PHP 8.2 or later
- Any architecture: pre-built binaries for amd64, compiles from source on arm64 (Apple Silicon)

## Install

```bash
ddev add-on get jeandavid/ddev-php-debugger
ddev restart
```

For local development / testing:

```bash
ddev add-on get /path/to/this/repo
ddev restart
```

## Usage

The addon is transparent — use DDEV's built-in xdebug commands as usual:

```bash
# Enable step-debugging (now powered by php-debugger)
ddev xdebug on

# Verify
ddev exec php -v
# Shows: "with PHP Debugger v0.1.0-dev"

# Disable
ddev xdebug off
```

Your IDE configuration (PHPStorm, VS Code, etc.) remains unchanged — php-debugger speaks the same DBGp protocol.

## How it works

At container build time, the addon:

1. Detects the PHP version and architecture
2. On amd64: downloads the matching pre-built binary from GitHub releases
3. On arm64: compiles php-debugger from source (first build takes ~40s)
4. Backs up the original `xdebug.so` → `xdebug.so.original`
5. Replaces `xdebug.so` with the php-debugger binary

The addon also overrides `xdebug.mode` to `debug` (instead of DDEV's default `debug,develop`) since php-debugger only supports step-debugging.

This means `ddev xdebug on` loads php-debugger instead of Xdebug, with zero UX change.

## Revert to Xdebug

```bash
ddev add-on remove php-debugger
ddev restart
```

This removes the custom Dockerfile — the next build uses the stock Xdebug.

## Running tests

```bash
bats tests/test.bats
```

## Links

- [php-debugger](https://github.com/pronskiy/php-debugger)
- [DDEV addons](https://ddev.readthedocs.io/en/stable/users/extend/additional-services/)
