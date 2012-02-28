
cat >"$3" <<EOF

# Sgouldbe present at least once
# NameVirtualHost *:80

<VirtualHost *:80>
  ServerName www.mildred.fr
  ServerAlias mildred.fr
  DocumentRoot $(pwd)/out
  <Directory />
    AllowOverride All
  </Directory>
</VirtualHost>

EOF
