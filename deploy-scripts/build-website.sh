#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
bundle config set --local path "vendor/bundle"
bundle install
bundle exec jekyll build
