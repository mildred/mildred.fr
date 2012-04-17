. ../vhost.sh

cat >"$3" <<EOF

server {
  listen 80 default_server;
  listen [::]:80 default_server ipv6only=on;
  server_name $domain;
  rewrite ^ http://$vhost.$domain\$request_uri? permanent;
}

server {
  listen 80;
  listen [::]:80;
  server_name $vhost.$domain;
  root "${PWD}/out";

EOF
cat >>"$3" <<"EOF"

  rewrite "^/(Blog/)?tags/([^/0-9]+).html$"         /tags/$2/    permanent;
  rewrite "^/(Blog/)?tags/([^/0-9]+)([0-9]+).html$" /tags/$2/$3/ permanent;
  rewrite "^/articles/([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)/(.*)$"  /Blog/$1/$2/$3/$4/$5 permanent;
  rewrite "^/Blog/blog/([0-9]{4})/([0-9]{2})/([0-9]{2})/(.*).html$" /Blog/$1/$2/$3/$4/   permanent;
  rewrite "^/Blog/blog/atom.xml$"              /atom.xml permanent;
  rewrite "^/Blog/(blog/index)?([0-9]+).html$" /Blog/$2/ permanent;
  rewrite "^/Blog/(Images|tags)/(.*)$"         /$1/$2    permanent;
  rewrite "^/Blog/blog/(.*)$"                  /Blog/$1  permanent;
  
  location /Blog/blog/2010/Images-SRS/ { return 410; }
  location /Blog/2010/Images-SRS/      { return 410; }
}

EOF

