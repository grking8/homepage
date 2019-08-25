#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir $STATIC_DIR
gem install bundler
bundle check --path vendor/bundle || bundle install --path vendor/bundle
bundle exec jekyll build
