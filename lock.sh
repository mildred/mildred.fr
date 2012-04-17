#!/bin/sh
cd "$(dirname "$0")"

pidfile(){
  : >> "$2"
  local pid="$(cat "$2")"
  if [ -n "$pid" ] && [ -e /proc/$pid ]; then
    return 1
  else
    echo $1 >"$2"
    return 0
  fi
}

pidfile 1 update.pid
