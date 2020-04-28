#!/bin/sh

base="$(cd "$(dirname "$0")/.."; echo "$PWD")"
PATH="$PATH:/$base/bin"

set -x
cd "$base"
exec devd -p 8079 -H \
  /=http://localhost:1313 \
  /admin/=http://localhost:8080/admin/ \
  /datamgr/=http://localhost:8081/datamgr/

