#!/bin/sh

cat <<EOF
---
title:      Photo Album
created_at: $(date +'%F %T %:z')
tags:
  - album
  - srs
filter:
  - markdown
---

Photo Album
===========

EOF

for t in thumb_*.png; do
  thumb="$t"
  photo="${t%.png}.jpeg"
  photo="${photo#thumb_}"
  echo '<div style="float: left; height: 200px; width: 200px;">'
  echo "<a href=\"$photo\"><img src=\"$thumb\" style=\"border: none;\"/></a>"
  echo '</div>'
done
