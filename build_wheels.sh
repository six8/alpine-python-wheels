#!/usr/bin/env bash

set -Eeuo pipefail

[ -n "${DEBUG:-}" ] && set -x

WHEELS_DIR="$PWD/wheels"
PIP="/opt/python/cp37-cp37m/bin/pip"
export PIP_CACHE_DIR="$PWD/.pip_cache"

function repair_wheel {
  local wheel="$1"
  if ! auditwheel show "$wheel" > /dev/null 2>&1; then
    # Pure python wheel, just copy it
    cp "$wheel" "$WHEELS_DIR"
  else
    out_dir="$(mktemp -d)"
    auditwheel repair "$wheel" -w "$out_dir"
    for whl in "$out_dir"/*.whl; do
      if [ -f "${WHEELS_DIR}/$(basename "$whl")" ]; then
        echo "Skip existing wheel $whl"
        continue
      fi

      mv "$whl" "$WHEELS_DIR"
    done
    rm -Rf "$out_dir"
  fi
}

rm -f "$WHEELS_DIR"/build/*.whl

# For URL/git requirements, download the sources
grep "@" "$PWD/requirements.txt" | "$PIP" download \
  --exists-action i \
  --find-links "file://$WHEELS_DIR/sources" \
  -r /dev/stdin \
  -d "$WHEELS_DIR/sources" \
  --no-deps

# From the downloaded sources, build the wheels. This is done manually instead of
# letting pip do it so we can get repeatable builds.
for source_file in "$WHEELS_DIR/sources"/*; do
  # SOURCE_DATE_EPOCH makes a repeatable timestamp for repeatable builds
  SOURCE_DATE_EPOCH="$(stat -c %Y "$source_file")" "$PIP" wheel \
    --no-index \
    --wheel-dir "$WHEELS_DIR/build" \
    --exists-action i \
    --find-links "file://$WHEELS_DIR" \
    --find-links "file://$WHEELS_DIR/build" \
    --find-links "file://$WHEELS_DIR/sources" \
    --no-deps \
    --no-build-isolation \
    "$source_file"
done

# Build wheels for non-URL/git requirements
grep -v "@" "$PWD/requirements.txt" | "$PIP" wheel \
  --wheel-dir "$WHEELS_DIR/build" \
  -r /dev/stdin \
  --exists-action i \
  --no-build-isolation \
  --find-links "file://$WHEELS_DIR" \
  --find-links "file://$WHEELS_DIR/build" \
  --find-links "file://$WHEELS_DIR/sources" \
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
