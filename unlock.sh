#!/bin/sh
cd "$(dirname "$0")"
: >> update.pid
if [ 1 = "$(cat update.pid)" ]; then
  rm -f update.pid
fi
