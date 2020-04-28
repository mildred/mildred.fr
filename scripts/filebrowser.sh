#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:/home/protected/bin:/home/private/go/bin"

exec >"$base/filebrowser.log" 2>&1
set -x
cd "$base"
exec filebrowser \
  --baseurl=/admin/ \
  --scope="$base" \
  --commands="git" \
  --staticgen=hugo \
  --port=8080 \
  --address=0.0.0.0
