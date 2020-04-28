#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:/home/protected/bin:/home/private/go/bin"

exec >"$base/hugo.log" 2>&1
set -x
cd "$base"
exec hugo -d /home/public/ -w

