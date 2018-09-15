#!/usr/bin/env sh

set -xe

DIR=/root/project/
. ${DIR}deploy.cfg
cd ..
echo "Authenticate to Google Cloud Platform..."
${DEPLOY_SCRIPTS_LIB_REPO}/gcp/authenticate.sh
${DEPLOY_SCRIPTS_LIB_REPO}/gcp/create-update-instance.sh
