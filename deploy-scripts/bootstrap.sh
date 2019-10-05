#!/usr/bin/env sh

set -xe

ssh-keyscan -H $BOOTSTRAP_REPO_DOMAIN >> ~/.ssh/known_hosts
BOOTSTRAP_DIR="bootstrap"
mkdir $BOOTSTRAP_DIR
cd $BOOTSTRAP_DIR
git clone $BOOTSTRAP_REPO_URL
cd ..
echo "Update conda"
conda update conda
echo "Build conda environment"
conda env update --name root --file ${BOOTSTRAP_DIR}/${BOOTSTRAP_REPO}/environment.yml
