#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:$base/bin"

set -x
cd "$base"
exec filebrowser2 \
  --baseurl=/admin \
  --database=filebrowser2.db \
  --port=8080 \
  --address=0.0.0.0

