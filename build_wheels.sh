#!/usr/bin/env bash

set -Eeuo pipefail

[ -n "${DEBUG:-}" ] && set -x

WHEELS_DIR="$PWD/wheels"

function repair_wheel {
  local wheel="$1"
  if ! auditwheel show "$wheel"; then
    echo "Skipping non-platform wheel $wheel"
  else
    auditwheel repair "$wheel" -w "$WHEELS_DIR"
  fi
}

rm -f "$WHEELS_DIR"/build/*.whl

for py_bin in /opt/python/cp37-cp37m/bin; do
  "${py_bin}/pip" wheel \
    --cache-dir "$PWD/.pip_cache" \
    --wheel-dir "$WHEELS_DIR/build" \
    -r "$PWD/requirements.txt" \
    --find-links "file://$WHEELS_DIR" \
    --find-links "file://$WHEELS_DIR/build" \
    --no-deps
done

# Bundle external shared libraries into the wheels
for whl in "$WHEELS_DIR"/build/*.whl; do
  if [ -f "${WHEELS_DIR}/$(basename "$whl")" ]; then
    # This looks to already be repaired, skip to avoid re-repair errors
    echo "Skip already repaired wheel $whl"
    continue
  fi
  repair_wheel "$whl"
done
