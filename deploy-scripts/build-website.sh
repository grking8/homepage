#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
# bundle config set --local path "$(pwd)/bundle"
echo list of files
pwd
bundle install
bundle exec jekyll build
