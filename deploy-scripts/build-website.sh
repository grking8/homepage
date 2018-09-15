#!/usr/bin/env bash

set -xe

. deploy.cfg
mkdir -p $STATIC_DIR
jekyll build
