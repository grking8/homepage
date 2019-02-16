#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
gem install bundler
bundle check || bundle update
bundle exec jekyll build
