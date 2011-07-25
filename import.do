(

for dir in ../survie; do

  list="$(egrep -i 'author:\s*Mildred' "$dir/content/articles"/* | cut -d: -f1 | uniq)"
  
  while read file; do
  
    basename="$(basename "$file")"
    dest="content/articles/$basename"
    
    if ! [ -e "content/articles/$basename" ]; then
      echo cp "$file" "$dest"
      cp "$file" "$dest"
    elif [ "$file" -nt "$dest" ]; then
      diff -u "$file" "$dest"
    fi
  
  done <<<"$list"

done

) >&2

