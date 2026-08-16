#!/usr/bin/env bash
# Parses every bundled JavaScript asset.
#
# These files never reach the Dart analyzer, so a syntax error in one is
# invisible until a document renders blank on a device. Requires Node.
set -euo pipefail
cd "$(dirname "$0")/.."

status=0
while IFS= read -r file; do
  if node --check "$file" 2>/dev/null; then
    printf '  ok    %s\n' "$file"
  else
    printf '  FAIL  %s\n' "$file"
    node --check "$file" || true
    status=1
  fi
done < <(find assets -name '*.js' | sort)

exit "$status"
