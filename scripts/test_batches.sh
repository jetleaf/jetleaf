#!/usr/bin/env bash
# Runs the monorepo test suite in small batches.
#
# Why: `dart test` in `libraries/jetleaf_core` (package:test JIT
# incremental frontend) hits its kernel-size ceiling and fails with
# ~57 "loading ..." errors when all ~210 test files share one
# frontend session. Splitting into small batches pins the shared
# kernel well below the ceiling and passes deterministically.
#
# CI uses this script. You can also use it locally:
#   ./scripts/test_batches.sh
#   ./scripts/test_batches.sh libraries/jetleaf_core  # one package
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

SWEEP_MODE="${1:-all}"
EXIT_CODE=0

run_package() {
  local pkg="$1"
  local label="$2"
  if [ ! -d "$pkg/test" ]; then
    return 0
  fi
  local has_tests
  has_tests=$(find "$pkg/test" -name "*_test.dart" -print -quit 2>/dev/null)
  if [ -z "$has_tests" ]; then
    echo "-- $label: no tests, skipping"
    return 0
  fi
  echo "-- $label"
  # Split into batches of 8 files, serial within each package.
  # Each batch is its own `dart test` invocation so the shared kernel
  # never accumulates 46 MB of compiled sources.
  find "$pkg/test" -name "*_test.dart" -print0 2>/dev/null \
    | xargs -0 -n 8 -I{} sh -c 'rm -rf .dart_tool/test && printf "%s\n" "{}" | xargs dart test --concurrency=1 2>&1' \
    || EXIT_CODE=1
}

case "$SWEEP_MODE" in
  all)
    for pkg in \
      libraries/jetleaf_core \
      libraries/jetleaf_tools \
      packages/jetson \
      packages/jtl \
      packages/jetleaf_resource \
      packages/jetleaf_retry \
      packages/jetleaf_scheduling \
      packages/jetleaf_validation \
      packages/jetleaf_actuator \
      packages/jetleaf_web \
      ; do
      run_package "$pkg" "$(basename "$pkg")"
    done
    ;;
  *)
    if [ -d "$SWEEP_MODE" ]; then
      run_package "$SWEEP_MODE" "$(basename "$SWEEP_MODE")"
    else
      echo "error: '$SWEEP_MODE' is not a directory under the workspace root" >&2
      exit 2
    fi
    ;;
esac

pkill -9 -f dart 2>/dev/null || true
exit $EXIT_CODE
