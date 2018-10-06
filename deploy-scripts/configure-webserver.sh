#!/usr/bin/env sh

set -xe

. deploy.cfg
cd ../${DEPLOY_SCRIPTS_REPO}/ssl
echo "Create SSL files..."
./create-ssl-files.sh true
mkdir -p ../../project/config
mv $SSL_PRIVATE_KEY_FILE ../../project/config
mv $SSL_CERTIFICATE_FILE ../../project/config
echo "Create webserver config..."
apk add gettext
cd ../..
envsubst '${SSL_CERTIFICATE_FILE},${SSL_PRIVATE_KEY_FILE}' \
< ${WEBSERVER_REPO}/ssl/nginx/default.conf \
> project/${CONFIG_DIR}/default.conf
