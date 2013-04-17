sign="0install run http://0install.net/2006/interfaces/0publish --xmlsign --key=9A7D2E2B"
unsign="0install run http://0install.net/2006/interfaces/0publish --unsign"

yes | $unsign weboob-config
$sign weboob-config
for app in $(0install run ./weboob-config applications); do
  if [ weboob-config != $app ]; then
    sed s/weboob-config/$app/g <weboob-config >$app
    yes | $unsign $app
    $sign $app
  fi
done
