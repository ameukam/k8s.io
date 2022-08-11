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

# common vars
script_name="$(basename "${BASH_SOURCE[0]%.*}")"
readonly script_name

CONFIG_FILE=${CONFIG_FILE:-"/tmp/rclone.conf"}
SOURCE_BUCKET=${SOURCE_BUCKET:-"us.artifacts.k8s-artifacts-prod.appspot.com"}
DESTINATION_BUCKET=${DESTINATION_BUCKET:-"prod-registry-k8s-io-us-east-2"}

function ensure_dependencies() {
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
    echo "Creating rclone configuration file..."
    cat <<EOF > "${CONFIG_FILE}"
[gs]
type = google cloud storage
anonymous = true
no_check_bucket = true
[s3]
type = s3
provider = AWS
env_auth = false
access_key_id = $AWS_ACCESS_KEY_ID
secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF
}

function sync_bucket() {
    if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
        echo "${FUNCNAME[0]}(source_bucket, destionation_bucket) requires 2 arguments" >&2
        return 1
    fi

    echo "${1}"
    echo "${2}"
    local source_bucket="${1}"
    local destination_bucket="${2}"

    rclone sync --config "${CONFIG_FILE}" -vvvvv "gs:${source-bucket}" "s3:${destination-bucket}" --fast-list --transfers 10000 --ignore-existing --disable-http2 --human-readable

    #rm -f /tmp/rclone.conf
}

function main() {
    ensure_dependencies
    check_credentials
    rclone_config
    sync_bucket "${SOURCE_BUCKET}" "${DESTINATION_BUCKET}"
}

main