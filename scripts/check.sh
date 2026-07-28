#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Backend: spotlessCheck, checkstyle, tests, coverage"
(cd "$ROOT/backend" && ./gradlew check)

echo "==> Flutter: analyze"
(cd "$ROOT/app" && flutter analyze)

echo "==> Flutter: test"
(cd "$ROOT/app" && flutter test)

echo "All checks passed."
