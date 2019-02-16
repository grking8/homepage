#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
bundle check --path vendor/bundle || bundle install --path vendor/bundle
bundle exec jekyll build
