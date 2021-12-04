#!/usr/bin/env sh

set -xe

sudo apt update || sudo apt update
sudo apt install jq
jq -n \
--arg gcp_project_id "$GCP_PROJECT_ID" \
--arg gcp_identity_service_account "$GCP_IDENTITY_SERVICE_ACCOUNT" \
--arg gcp_identity_service_account_email "$GCP_IDENTITY_SERVICE_ACCOUNT_EMAIL" \
--arg gcp_identity_service_account_key_path "$GCP_IDENTITY_SERVICE_ACCOUNT_KEY_PATH" \
--arg gcp_resource_service_account "$GCP_RESOURCE_SERVICE_ACCOUNT" \
--arg gcp_resource_service_account_email "$GCP_RESOURCE_SERVICE_ACCOUNT_EMAIL" \
--arg gcp_region "$GCP_REGION" \
--arg gcloud_sdk_version "$GCLOUD_SDK_VERSION" \
--arg static_dir "$STATIC_DIR" \
--arg domain "$DOMAIN" \
--arg subdomain "$SUBDOMAIN" \
--arg main_page "$MAIN_PAGE" \
--arg not_found_page "$NOT_FOUND_PAGE" \
--arg initial_run "$INITIAL_RUN" \
'{"gcp-project-id": $gcp_project_id, "gcp-identity-service-account": $gcp_identity_service_account, "gcp-identity-service-account-email": $gcp_identity_service_account_email, "gcp-identity-service-account-key-path": $gcp_identity_service_account_key_path, "gcp-resource-service-account": $gcp_resource_service_account, "gcp-resource-service-account-email": $gcp_resource_service_account_email, "gcp-region": $gcp_region, "gcloud-sdk-version": $gcloud_sdk_version, "static-dir": $static_dir, "domain": $domain, "subdomain": $subdomain, "main-page": $main_page, "not-found-page": $not_found_page, "initial-run": $initial_run}' >> "$1"
