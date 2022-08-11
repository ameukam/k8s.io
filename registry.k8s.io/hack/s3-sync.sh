#!/usr/bin/env bash

# Copyright 2022 The Kubernetes Authors.
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

# Diff the listings of two bucket paths

set -o errexit
set -o nounset
set -o pipefail

CONFIG_FILE=${CONFIG_FILE:-"/tmp/rclone.conf"}
REGION=${REGION:-"us-east-2"}
SOURCE_BUCKET=${SOURCE_BUCKET:-"us.artifacts.k8s-artifacts-prod.appspot.com"}
DESTINATION_BUCKET=${DESTINATION_BUCKET:-"prod-registry-k8s-io-${REGION}"}

function ensure_dependencies() {
    if [ -z "$(which aws)" ]; then
        echo "Please install aws"
        exit 1
    fi

    if [ -z "$(which rclone)" ]; then
        echo "Please install rclone"
        exit 1
    fi
}

function check_credentials() {
    if [[ -z "$AWS_ACCESS_KEY_ID" ]] ; then
        echo "Please set AWS_ACCESS_KEY_ID"
    exit 1
    fi
    if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "Please AWS_SECRET_ACCESS_KEY"
    exit 1
    fi
}

function rclone_config() {
    if [ $# -lt 1 ] ; then
        echo "No region provided"
        exit 1
    fi

    local region="${1}"

    echo "Getting credentials for synchronization"
    role_credentials="$(aws sts assume-role \
        --role-arn "arn:aws:iam::513428760722:role/registry.k8s.io_s3writer" \
        --role-session-name "bucket-writer" --output json)"
    aws_access_key_id=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
    aws_secret_access_key=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
    aws_session_token=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)

    echo "Ensure rclone configuration file..."
    cat <<EOF > "${CONFIG_FILE}"
[gcs]
type = google cloud storage
anonymous = true
no_check_bucket = true

[s3]
type = s3
provider = AWS
env_auth = false
access_key_id = $aws_access_key_id
secret_access_key = $aws_secret_access_key
session_token = $aws_session_token
region = $region
EOF
}

function sync_bucket() {
    if [ $# -lt 3 ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "${FUNCNAME[0]}(source_bucket, destionation_bucket) requires 2 arguments" >&2
        return 1
    fi

    local source_bucket="${1}"
    local destination_bucket="${2}"
    local region="${3}"

    rclone_config "${region}"

    echo "Syncing objects from ${source_bucket} to ${destination_bucket}"
    rclone sync --config "${CONFIG_FILE}" -vv "gcs:${source_bucket}" "s3:${destination_bucket}" \
        --fast-list --transfers 10000 --ignore-existing --disable-http2 --human-readable

    rm -f /tmp/rclone.conf
}

function main() {
    ensure_dependencies
    check_credentials
    sync_bucket "${SOURCE_BUCKET}" "${DESTINATION_BUCKET}" "${REGION}"
}

main
