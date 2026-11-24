#!/usr/bin/env bash
# Publish one package of the Jetleaf workspace to pub.dev from a local machine.
#
# `dart pub publish` reads .pubignore from the workspace root even when it is
# run inside a child package. The root .pubignore excludes `libraries/` and
# `packages/` so those files stay out of the root `jetleaf` package archive —
# but that also empties the archive of every child package. This script
# temporarily strips just those two rules, publishes, then restores the file.
#
# Usage:
#   scripts/publish-package.sh <package-dir> [dart pub publish args...]
#
# Examples:
#   scripts/publish-package.sh libraries/jetleaf_core --dry-run
#   scripts/publish-package.sh packages/jetleaf_security --force
#   scripts/publish-package.sh . --dry-run          # root package (no swap)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:?Usage: scripts/publish-package.sh <package-dir> [dart pub publish args...]}"
shift || true

if [ ! -f "$ROOT_DIR/$TARGET/pubspec.yaml" ]; then
  echo "Error: $ROOT_DIR/$TARGET/pubspec.yaml not found." >&2
  exit 1
fi

PUBIGNORE="$ROOT_DIR/.pubignore"
BACKUP="$(mktemp)"
HAD_PUBIGNORE=false

if [ "$TARGET" != "." ] && [ -f "$PUBIGNORE" ]; then
  HAD_PUBIGNORE=true
  cp "$PUBIGNORE" "$BACKUP"
  # Read from the backup: redirecting into .pubignore would truncate the source.
  grep -v -x -e 'libraries/' -e 'packages/' "$BACKUP" > "$PUBIGNORE" || true
fi

restore() {
  # Only restore when we actually modified the file. The root package keeps the
  # original .pubignore (it needs the child-package exclusions).
  if [ "$HAD_PUBIGNORE" = "true" ]; then
    cp "$BACKUP" "$PUBIGNORE"
  fi
  rm -f "$BACKUP"
}
trap restore EXIT

echo "Publishing $TARGET from $ROOT_DIR"
cd "$ROOT_DIR/$TARGET"
dart pub publish "$@"
