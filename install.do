exec >&2
redo-ifchange nginx.conf nginx.conf cron config

if [ -e ./config ]; then
  . ./config
fi
: ${site_name:=$(pwd | xargs basename)}

cp cron /etc/cron.d/http-$site_name
cp httpd.conf "/etc/apache2/sites-available/$site_name"
cp nginx.conf "/etc/nginx/sites-available/$site_name"

ln -sf "../sites-available/$site_name" "/etc/nginx/sites-enabled/$site_name"
service nginx reload

# a2ensite "$site_name"
# service apache2 reload

