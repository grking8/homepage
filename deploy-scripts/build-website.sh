#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
mkdir -p .bundle/config
jekyll build
