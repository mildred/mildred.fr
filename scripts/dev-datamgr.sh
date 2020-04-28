#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:$base/bin"

set -x
cd "$base"
exec datamgr -listen :8081

