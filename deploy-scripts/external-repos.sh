#!/usr/bin/env sh
#
# Download external repositories
#
# $1 - running on Alpine Linux
#

set -e

DIR=/root/project/
. ${DIR}deploy.cfg
if [ $1 = true ]; then
    apk update
    apk add openssh-client
    apk add git
fi
mkdir /root/.ssh
ssh-keyscan -H $EXTERNAL_GITHOST >> ~/.ssh/known_hosts
cd ..
git clone $WEBSERVER_REPO_URL
git clone $DEPLOY_SCRIPTS_REPO_URL
