#!/bin/bash

echo -e "\033[0;32mBuild...\033[0m"

HUGO_VERSION=0.52
if ! [[ -e hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz ]]; then
  wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz
fi
tar zxvf hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz hugo

rm -rf public
git worktree prune
git worktree add -B gh-pages public empty

./hugo
