rm -rf "$2.tidy"
cp -a --reflink "$2" "$2.tidy"

[ -e node_modules/html ] || npm install html
cp "$PWD/node_modules/html/bin/html.js" html.js
sed -i -e 's/{indent_size: 2}/{indent_size: 2, max_char: 192, unformatted: []}/' -e 's|../lib/html|html|' html.js
HTML="$PWD/html.js"

cd "$2.tidy"
find . -name "*.html" -print0 | xargs -0 $HTML


find . -name "*.html" | while read f; do
  # reorder attributes
  sed -ri 's:<meta content="([^"]*)" (name|http-equiv)="([^"]*)">:<meta \2="\3" content="\1">:' "$f"
  sed -ri 's:<link href="([^"]*)" rel="([^"]*)":<link rel="\2" href="\1":' "$f"
  sed -ri 's:<link(\s+[^>]*)(\s+)(rel|ref)="([^"]*)":<link\2\3="\4"\1:' "$f"
  sed -ri 's:media="screen" type="text/css":type="text/css" media="screen":' "$f"
  sed -ri 's:href="([^"]*)" class="([^"]*)":class="\2" href="\1":' "$f"
  sed -ri 's:id="([^"]*)" class="([^"]*)":class="\2" id="\1":' "$f"
  sed -ri 's:src="([^"]*)" alt="([^"]*)" class="([^"]*)":alt="\2" class="\3" src="\1":' "$f"

  # Fix
  sed -ri '/<meta name="keywords"/ { s/, /,/g }' "$f"
  sed -ri 's:<a href="../../../../..">Home</a>:<a href="../../../../../">Home</a>:' "$f"
  
  # remove tag list (temporary)
  sed -i '/<ul class="tags">/,/<\/ul>/ d' "$f"
  
  # Normalize
  sed -ri 's:":'"'"':g' "$f"
done

rm "$HTML"
