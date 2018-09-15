#!/usr/bin/env sh

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
jekyll build
