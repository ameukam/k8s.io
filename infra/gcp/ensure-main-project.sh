#!/usr/bin/env bash

# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script creates & configures the "main" GCP project for Kubernetes.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
. "${SCRIPT_DIR}/lib.sh"

function usage() {
    echo "usage: $0" > /dev/stderr
    echo > /dev/stderr
}

if [ $# != 0 ]; then
    usage
    exit 1
fi

# The GCP project name.
PROJECT="kubernetes-public"

# The BigQuery dataset for billing data.
BQ_BILLING_DATASET="kubernetes_public_billing"

# The BigQuery admins group.
BQ_ADMINS_GROUP="k8s-infra-bigquery-admins@kubernetes.io"

# The cluster admins group.
CLUSTER_ADMINS_GROUP="k8s-infra-cluster-admins@kubernetes.io"

# The accounting group.
ACCOUNTING_GROUP="k8s-infra-gcp-accounting@kubernetes.io"

# The GCS bucket which hold terraform state for clusters
CLUSTER_TERRAFORM_BUCKET="k8s-infra-clusters-terraform"

# The GKE security groups group
CLUSTER_USERS_GROUP="gke-security-groups@kubernetes.io"

# The DNS admins group.
DNS_GROUP="k8s-infra-dns-admins@kubernetes.io"

# Buckets for the logs of prow
PROW_BUCKETS=(
    k8s-prow-infra-logs
)

color 6 "Ensuring project exists: ${PROJECT}"
ensure_project "${PROJECT}"

# Enable APIs we know we need
apis=(
    bigquery-json.googleapis.com
    compute.googleapis.com
    container.googleapis.com
    dns.googleapis.com
    logging.googleapis.com
    monitoring.googleapis.com
    oslogin.googleapis.com
    secretmanager.googleapis.com
    storage-component.googleapis.com
)
ensure_only_services "${PROJECT}" "${apis[@]}"

color 6 "Ensuring the cluster terraform-state bucket exists"
ensure_private_gcs_bucket \
    "${PROJECT}" \
    "gs://${CLUSTER_TERRAFORM_BUCKET}"


color 6 "Ensuring all the prow buckets exist"
for bucket in "${PROW_BUCKETS[@]}"; do
    color 6 "Ensuring bucket ${bucket} exists and is only word-readable"
    ensure_public_gcs_bucket "${PROJECT}" "gs://${bucket}"

    local SERVICE_ACCOUNT_NAME="${bucket}-sa"
    local SERVICE_ACCOUNT_EMAIL="$(svc_acct_email "${PROJECT}" \
        "${SERVICE_ACCOUNT_NAME}")"
    local SECRET_ID="${SERVICE_ACCOUNT_NAME}-key"
    local KEY_FILE="${TMPDIR}/key.json"

    color 6 "Creating service account: ${SERVICE_ACCOUNT_NAME}"
    ensure_service_account \
        "${PROJECT}" \
        "${SERVICE_ACCOUNT_NAME}" \
        "${SERVICE_ACCOUNT_NAME}"

    color 6 "Empowering service account: ${SERVICE_ACCOUNT_NAME}"
    empower_svcacct_to_write_gcs_bucket "${SERVICE_ACCOUNT_EMAIL}" "gs://${bucket}"

    color 6 "Creating private key for service account: ${SERVICE_ACCOUNT_NAME}"
    gcloud iam service-accounts keys create "${KEY_FILE}" \
        --project "${PROJECT}" \
        --iam-account "${SERVICE_ACCOUNT_EMAIL}"

    color 6 "Ensure secret ${SECRET_ID} exists"
    gcloud secrets create "${SECRET_ID}" \
        --project "${PROJECT}" \
        --replication-policy "automatic"

    color 6 "Adding private key to secret ${SECRET_ID}"
    gcloud secrets versions add "${SECRET_ID}" \
        --project "${PROJECT}" \
        --data-file "${KEY_FILE}"

    color 6 "Empowering k8s-infra-prow-oncall@kubernetes.io to read secret ${SECRET_ID}"
    ensure_secrets_role_binding \
        "projects/${PROJECT}/secrets/${SECRET_ID}" \
        "group:k8s-infra-prow-oncall@kubernetes.io" \
        "roles/secretmanager.secretAccessor"

done 2>&1 | indent

color 6 "Empowering BigQuery admins"
ensure_project_role_binding \
    "${PROJECT}" \
    "group:${BQ_ADMINS_GROUP}" \
    "roles/bigquery.admin"

color 6 "Empowering cluster admins"
# TODO: this can also be a custom role
cluster_admin_roles=(
    roles/compute.viewer
    roles/container.admin
    roles/compute.loadBalancerAdmin
    $(custom_org_role_name iam.serviceAccountLister)
)
for role in "${cluster_admin_roles[@]}"; do
    ensure_project_role_binding "${PROJECT}" "group:${CLUSTER_ADMINS_GROUP}" "${role}"
done
# TODO(spiffxp): remove when bindings for custom project role are gone
ensure_removed_project_role_binding "${PROJECT}" "group:${CLUSTER_ADMINS_GROUP}" "$(custom_project_role_name "${PROJECT}" ServiceAccountLister)"
ensure_removed_custom_project_iam_role "${PROJECT}" "ServiceAccountLister"

color 6 "Empowering cluster admins to own gs://${CLUSTER_TERRAFORM_BUCKET}"
ensure_gcs_role_binding \
    "gs://${CLUSTER_TERRAFORM_BUCKET}" \
    "group:${CLUSTER_ADMINS_GROUP}" \
    "objectAdmin"
ensure_gcs_role_binding \
    "gs://${CLUSTER_TERRAFORM_BUCKET}" \
    "group:${CLUSTER_ADMINS_GROUP}" \
    "legacyBucketOwner"

color 6 "Empowering cluster users"
ensure_project_role_binding \
    "${PROJECT}" \
    "group:${CLUSTER_USERS_GROUP}" \
    "roles/container.clusterViewer"

color 6 "Empowering GCP accounting"
ensure_project_role_binding \
  "${PROJECT}" \
  "group:${ACCOUNTING_GROUP}" \
  "roles/bigquery.jobUser"

color 6 "Ensuring the k8s-infra-gcp-auditor serviceaccount exists"
ensure_service_account \
  "${PROJECT}" \
  "k8s-infra-gcp-auditor" \
  "Grants readonly access to org resources"

color 6 "Empowering k8s-infra-gcp-auditor serviceaccount to be used on trusted build cluster"
empower_ksa_to_svcacct \
  "k8s-infra-prow-build-trusted.svc.id.goog[test-pods/k8s-infra-gcp-auditor]" \
  "${PROJECT}" \
  $(svc_acct_email "${PROJECT}" "k8s-infra-gcp-auditor")
# TODO(spiffxp): delete this binding
empower_ksa_to_svcacct \
  "kubernetes-public.svc.id.goog[test-pods/k8s-infra-gcp-auditor]" \
  "${PROJECT}" \
  $(svc_acct_email "${PROJECT}" "k8s-infra-gcp-auditor")

color 6 "Ensuring the k8s-infra-dns-updater serviceaccount exists"
ensure_service_account \
    "${PROJECT}" \
    "k8s-infra-dns-updater" \
    "k8s-infra dns updater"

color 6 "Empowering k8s-infra-dns-updater serviceaccount to be used on build cluster"
empower_ksa_to_svcacct \
    "k8s-infra-prow-build-trusted.svc.id.goog[test-pods/k8s-infra-dns-updater]" \
    "${PROJECT}" \
    "$(svc_acct_email "${PROJECT}" "k8s-infra-dns-updater")"

color 6 "Empowering ${DNS_GROUP}"
color 6 "Empowering BigQuery admins"
ensure_project_role_binding \
    "${PROJECT}" \
    "group:${DNS_GROUP}" \
    "roles/dns.admin"

# Monitoring
MONITORING_SVCACCT_NAME="$(svc_acct_email "${PROJECT}" \
    "k8s-infra-monitoring-viewer")"

color 6 "Ensuring the k8s-infra-monitoring-viewer serviceaccount exists"
ensure_service_account \
    "${PROJECT}" \
    "k8s-infra-monitoring-viewer" \
    "k8s-infra monitoring viewer"

color 6 "Empowering k8s-infra-monitoring-viewer serviceaccount to be used on the 'aaa' cluster inside the 'monitoring' namespace"
empower_ksa_to_svcacct \
    "kubernetes-public.svc.id.goog[monitoring/k8s-infra-monitoring-viewer]" \
    "${PROJECT}" \
    "${MONITORING_SVCACCT_NAME}"

color 6 "Empowering service account ${MONITORING_SVCACCT_NAME}"
ensure_project_role_binding \
    "${PROJECT}" \
    "serviceAccount:${MONITORING_SVCACCT_NAME}" \
    "roles/monitoring.viewer"

# Bootstrap DNS zones
ensure_dns_zone "${PROJECT}" "k8s-io" "k8s.io"
ensure_dns_zone "${PROJECT}" "kubernetes-io" "kubernetes.io"
ensure_dns_zone "${PROJECT}" "x-k8s-io" "x-k8s.io"
ensure_dns_zone "${PROJECT}" "k8s-e2e-com" "k8s-e2e.com"
ensure_dns_zone "${PROJECT}" "canary-k8s-io" "canary.k8s.io"
ensure_dns_zone "${PROJECT}" "canary-kubernetes-io" "canary.kubernetes.io"
ensure_dns_zone "${PROJECT}" "canary-x-k8s-io" "canary.x-k8s.io"
ensure_dns_zone "${PROJECT}" "canary-k8s-e2e-com" "canary.k8s-e2e.com"

color 6 "Creating the BigQuery dataset for billing data"
if ! bq --project_id "${PROJECT}" ls "${BQ_BILLING_DATASET}" >/dev/null 2>&1; then
    bq --project_id "${PROJECT}" mk "${BQ_BILLING_DATASET}"
fi

color 6 "Setting BigQuery permissions"

# Merge existing permissions with the ones we need to exist.  We merge
# permissions because:
#   * The full list is large and has stuff that is inherited listed in it
#   * All of our other IAM binding logic calls are additive

CUR=${TMPDIR}/k8s-infra-bq-access.before.json
bq show --format=prettyjson "${PROJECT}":"${BQ_BILLING_DATASET}"  > "${CUR}"

ENSURE=${TMPDIR}/k8s-infra-bq-access.ensure.json
cat > "${ENSURE}" << __EOF__
{
  "access": [
    {
      "groupByEmail": "${ACCOUNTING_GROUP}",
      "role": "READER"
    },
    {
      "groupByEmail": "${ACCOUNTING_GROUP}",
      "role": "roles/bigquery.metadataViewer"
    },
    {
      "groupByEmail": "${ACCOUNTING_GROUP}",
      "role": "roles/bigquery.user"
    }
  ]
}
__EOF__

FINAL=${TMPDIR}/k8s-infra-bq-access.final.json
jq -s '.[0].access + .[1].access | { access: . }' "${CUR}" "${ENSURE}" > "${FINAL}"

bq update --source "${FINAL}" "${PROJECT}":"${BQ_BILLING_DATASET}"

color 4 "To enable billing export, a human must log in to the cloud"
color 4 -n "console.  Go to "
color 6 -n "Billing"
color 4 -n "; "
color 6 -n "Billing export"
color 4 " and export to BigQuery"
color 4 -n "in project "
color 6 -n "${PROJECT}"
color 4 -n " dataset "
color 6 -n "${BQ_BILLING_DATASET}"
color 4 " ."
echo
color 4 "Press enter to acknowledge"
read -s

color 6 "Done"
