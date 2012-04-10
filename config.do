exec >"$3"

cat <<EOF

mail_from=`whoami`@`hostname`
mail_rcpt=`whoami`@`hostname`

EOF


