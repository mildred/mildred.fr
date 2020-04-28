#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:/home/protected/bin:/home/private/go/bin"

exec >"$base/datamgr.log" 2>&1
set -x
cd "$base"
exec datamgr -listen :8081

