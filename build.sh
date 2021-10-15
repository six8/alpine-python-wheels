#!/usr/bin/env bash

set -Eeuo pipefail

[ -n "${DEBUG:-}" ] && set -x

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alpine-python-wheels:latest"

docker build -t "$IMAGE_NAME" .

docker_args=(
  --rm
  -v "$DIR:$DIR"
  -w "$DIR"
  -u "$(id -u):$(id -g)"
)

if [ -t 0 ]; then
  docker_args+=(-it)
fi

docker run "${docker_args[@]}" "$IMAGE_NAME"
