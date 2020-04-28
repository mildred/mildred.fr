#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:$base/bin"

set -x
cd "$base"
exec filebrowser \
  --baseurl=/admin \
  --scope="$base" \
  --commands="git" \
  --staticgen=hugo \
  --port=8080 \
  --address=0.0.0.0

