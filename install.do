exec >&2
redo-ifchange httpd.conf
sitename="$(basename "`pwd`")"
cp httpd.conf "/etc/apache2/sites-available/$sitename"
a2ensite "$sitename"
service apache2 reload
