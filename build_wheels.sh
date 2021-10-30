#!/usr/bin/env bash

set -Eeuo pipefail

[ -n "${DEBUG:-}" ] && set -x

WHEELS_DIR="$PWD/wheels"
PIP="/opt/python/cp37-cp37m/bin/pip"

function repair_wheel {
  local wheel="$1"
  if ! auditwheel show "$wheel"; then
    # Pure python wheel, just copy it
    cp "$wheel" "$WHEELS_DIR"
  else
    auditwheel repair "$wheel" -w "$WHEELS_DIR"
  fi
}

rm -f "$WHEELS_DIR"/build/*.whl

"$PIP" wheel \
  --cache-dir "$PWD/.pip_cache" \
  --wheel-dir "$WHEELS_DIR/build" \
  -r "$PWD/requirements.txt" \
  --find-links "file://$WHEELS_DIR" \
  --find-links "file://$WHEELS_DIR/build" \
  --find-links "file://$WHEELS_DIR/sources" \
  --no-deps

# For git requirements, also download the source
grep "@" "$PWD/requirements.txt" | "$PIP" download \
  --cache-dir "$PWD/.pip_cache" \
  --exists-action i \
  --find-links "file://$WHEELS_DIR/sources" \
  -r /dev/stdin \
  -d "$WHEELS_DIR/sources" \
  --no-deps

# Bundle external shared libraries into the wheels
for whl in "$WHEELS_DIR"/build/*.whl; do
  if [ -f "${WHEELS_DIR}/$(basename "$whl")" ]; then
    # This looks to already be repaired, skip to avoid re-repair errors
    echo "Skip existing wheel $whl"
    continue
  fi
  repair_wheel "$whl"
done
