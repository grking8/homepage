#!/usr/bin/env sh

set -e

echo "${GCP_IDENTITY_SERVICE_ACCOUNT_KEY}" | base64 --decode --ignore-garbage > "${GCP_IDENTITY_SERVICE_ACCOUNT_KEY_PATH}"
gcloud auth activate-service-account "$GCP_IDENTITY_SERVICE_ACCOUNT_EMAIL" --key-file="${GCP_IDENTITY_SERVICE_ACCOUNT_KEY_PATH}"
gcloud config set project "$GCP_PROJECT_ID"
gcloud config set auth/impersonate_service_account "$GCP_RESOURCE_SERVICE_ACCOUNT_EMAIL"
