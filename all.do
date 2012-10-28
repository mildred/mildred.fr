exec >&2
# rm -rf webgen.cache
# rake --trace
ruby1.8 -I webgen/lib webgen/bin/webgen
