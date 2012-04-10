exec >&2
redo-ifchange httpd.conf cron config

if [ -e ./config ]; then
  . ./config
fi
: ${site_name:=$(pwd | xargs basename)}

cp cron /etc/cron.d/http.$site_name
cp httpd.conf "/etc/apache2/sites-available/$site_name"
a2ensite "$site_name"
service apache2 reload

