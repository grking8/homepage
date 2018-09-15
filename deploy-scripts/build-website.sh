#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
bundle exec jekyll build
