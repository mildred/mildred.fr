cat >"$3" <<EOF

PATH=$PATH

* * * * * root $(pwd)/update.sh

EOF

chmod 0644 "$3"

