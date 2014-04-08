redo-ifchange tags.tags.taglist

(
echo "{\"all_tags\": ["
sep=""
cat "tags.tags.taglist" | while read tag; do
  printf '%s"%s"' "$sep" "$tag"
  sep=','
done
echo "]}"
)>"$3"
