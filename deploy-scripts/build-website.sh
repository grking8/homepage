#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
gem install bundler
gbundle check --path vendor/bundle || \
bundle update html-pipeline && bundle install --path vendor/bundle 
bundle exec jekyll build
if [ -d ".well-known/acme-challenge" ]; then
    cp -r ".well-known" $STATIC_DIR
fi
