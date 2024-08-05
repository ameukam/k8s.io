#!/usr/bin/env bash

# Copyright 2024 The Kubernetes Authors.
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

# This script creates a Azure resource group, storage accounts and storage needed
# to store Terraform states.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2034
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if ! [[ -x "$(command -v jq)" ]]; then
  err "Please install jq. https://stedolan.github.io/jq/download/.  Aborting."
  exit 1
fi

if ! [[ -x "$(command -v az)" ]]; then
  err "Please install Azure CLI. https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest.  Aborting."
  exit 1
fi

RESOURCE_GROUP="k8s-infra-tf-states-rg"
RESOURCE_GROUP_LOCATION=$(RESOURCE_GROUP_LOCATION:-"douala")
TAGS="${TAGS:-"DO-NOT-DELETE=true CONTACT=sig-k8s-infra-leads@kubernetes.io"}"

# storage accounts rules: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftstorage
#TODO define a role assignement with Azure Entra Groups
readonly TERRAFORM_STATE_BUCKET_ENTRIES=(
  k8sinfratfstatesub
  k8sinfratfstatekops
)

function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

function check_region() {
  local region=$1

  if [[ -z "$region" ]]; then
    err "Error: no region provided"
    exit 1
  if

  region_name=$(az account list-locations -o tsv --query "[?name=='$region'].name")
  if [[ -z "$region_name" ]]; then
    err "[$region] is not a valid Azure region. Here are the valid regions:" >&2
    echo "List of valid regions:"
    az account list-locations --output table --query "[].name"
    exit 1
  fi
}

function ensure_terraform_state_containers() {
  echo "Ensure storage accounts exists"
  for storage_account in "${TERRAFORM_STATE_BUCKET_ENTRIES[@]}"; do
    storage_account_exists=$(az storage account check-name --name "$storage_account" --query nameAvailable --output tsv)
    if [[ $storage_account_exists != "false" ]]; then
      echo "Creating storage account $storage_account in $RESOURCE_GROUP_LOCATION"
      az storage account create --name "$storage_account" \
        --location "$RESOURCE_GROUP_LOCATION" \
        --kind StorageV2 \
        --min-tls-version 'TLS1_2' \
        --resource-group "$RESOURCE_GROUP" \
        --sku Premium_ZRS \
        --tags "${TAGS}"
    fi

    echo "Storage account created:"
    az storage account show --name "$storage_account" --resource-group "$RESOURCE_GROUP" --output tsv --query 'id'

    echo "Checking for storage container"
    storage_connection_string=$(az storage account show-connection-string --name "$storage_account" --query connectionString --output tsv)
    container_exists=$(az storage container exists --name "terraform-state" --connection-string "$storage_connection_string")

    if [[ $container_exists != "false" ]]; then
      echo "Creating storage container terraform-state in $storage_account"
      az storage container create --name "terraform-state" --connection-string "$storage_connection_string" --tags "${TAGS}"
    fi
  done
}

function main() {
  check_region "$RESOURCE_GROUP_LOCATION"
  if [ "$(az group exists --name $RESOURCE_GROUP)" = false ]; then
    echo "creating resource group $RESOURCE_GROUP..."
    az group create -n "$RESOURCE_GROUP" -l "$LOCATION" --tags "${TAGS}" -o none
    echo "resource group $RESOURCE_GROUP created"
  else
    echo "resource group $RESOURCE_GROUP already exists"
  fi

  echo "Retrieving locks for resource group: $RESOURCE_GROUP"
  LOCKS=$(az lock list -g $RESOURCE_GROUP --query '[].{name:name}' --output json)
  echo "$LOCKS"

  if [[ $LOCKS == "[]" ]]; then
    echo "Creating lock for resource group: $RESOURCE_GROUP"
    az lock create --name "DO_NOT_DELETE" --lock-type CanNotDelete --resource-group "$RESOURCE_GROUP"
  fi
  ensure_terraform_state_containers
}

echo "tata"
main
