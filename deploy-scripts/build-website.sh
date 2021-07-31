#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
rm Gemfile.lock
gem install bundler
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec jekyll build
if [ -d ".well-known/acme-challenge" ]; then
    cp -r ".well-known" $STATIC_DIR
fi
