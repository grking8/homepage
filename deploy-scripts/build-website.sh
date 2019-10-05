#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
gem install bundler
bundle check --path vendor/bundle || bundle install --full-index --path vendor/bundle 
bundle exec jekyll build
if [ -d ".well-known/acme-challenge" ]; then
    cp -r ".well-known" $STATIC_DIR
fi
