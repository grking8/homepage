#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
gem install bundler
gem update bundler
pwd
ls
bundle install
bundle exec jekyll build
if [ -d ".well-known/acme-challenge" ]; then
    cp -r ".well-known" $STATIC_DIR
fi
