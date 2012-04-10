#!/bin/sh

pidfile(){
  : >> "$2"
  local pid="$(cat "$2")"
  if [ -n "$pid" ] && [ -e /proc/$pid ]; then
    return 1
  else
    echo $$ >"$2"
    return 0
  fi
}


if [ -f "./config" ]; then
  . "./config"
fi

: ${mail_from:=`whoami`@`hostname`}
: ${mail_rcpt:=`whoami`@`hostname`}
: ${origin:=origin}
: ${site_name:=$(pwd | xargs basename)}

log(){
  logger -s -t "$site_name" -p daemon.info "$*"
}

notice(){
  log "Mail from $mail_from to $mail_rcpt: $1"
  sendmail -t <<EOF
From: $mail_from
To: $mail_rcpt
Date: $(date "+%a, %e %b %Y %H:%M:%S %z")
Subject: $1

$2
EOF
}

if ! pidfile $$ update.pid; then
  log "Already Running"
  exit 0
fi

log "Updating website at $(pwd)..."

git fetch $origin
git add -A
git stash
git reset --hard $origin/master
git submodule update --recursive
: >> out.rev
rev=$(git rev-parse HEAD)
if [ "$rev" != "$(cat out.rev)" ]; then
  log "Git change: $(cat out.rev) -> $rev"
  notice "Updating website $(pwd)" "Git change: $(cat out.rev) -> $rev\n\n$(rake)"
fi
echo "$rev" > out.rev

