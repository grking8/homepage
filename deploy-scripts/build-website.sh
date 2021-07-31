#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
gem install bundler
bundle config set --local path 'vendor/bundle'
bundle check || bundle update html-pipeline && bundle install
bundle exec jekyll build
if [ -d ".well-known/acme-challenge" ]; then
    cp -r ".well-known" $STATIC_DIR
fi
