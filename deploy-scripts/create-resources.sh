#!/usr/bin/env sh

set -xe

gcloud deployment-manager deployments create \
"${CIRCLE_PROJECT_REPONAME}-service-account" \
--template "dm_templates/service_account.py" \
--properties \
"GCP_IDENTITY_SERVICE_ACCOUNT_EMAIL:${GCP_IDENTITY_SERVICE_ACCOUNT_EMAIL},\
GCP_RESOURCE_SERVICE_ACCOUNT:${GCP_RESOURCE_SERVICE_ACCOUNT}"

gcloud deployment-manager deployments create \
"${CIRCLE_PROJECT_REPONAME}-bucket" \
--template "dm_templates/bucket.py" \
--properties \
"SUBDOMAIN:${SUBDOMAIN},\
GCP_REGION:${GCP_REGION},\
MAIN_PAGE:${MAIN_PAGE},\
NOT_FOUND_PAGE:${NOT_FOUND_PAGE}"
gsutil -m cp -R "${STATIC_DIR}"/* "gs://${SUBDOMAIN}"
