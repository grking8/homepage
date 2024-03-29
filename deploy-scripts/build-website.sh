#!/usr/bin/env sh

set -xe

mkdir $STATIC_DIR
gem install bundler -v 2.2.21
bundle check --path vendor/bundle || \
bundle update html-pipeline && bundle install --path vendor/bundle 
bundle exec jekyll build
