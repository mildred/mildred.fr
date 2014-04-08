#!.../generator

rm -rf out.tmp

cp -a --reflink static out.temp
generate src out.temp

rm -rf out
mv out.temp out
