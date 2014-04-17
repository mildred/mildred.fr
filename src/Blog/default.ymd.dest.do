
JSONTOOL=../../node_modules/jsontool/lib/jsontool.js

redo-ifchange "$2.ymd.meta.json"
publish=$($JSONTOOL publish <"$2.ymd.meta.json")

if [ false = "$publish" ]; then
  : >"$3"
  exit
fi


echo "$2/index.html" | sed "s:-:/:" | sed "s:-:/:" | sed "s:-:/:" >"$3"

