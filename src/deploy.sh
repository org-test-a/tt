#!/bin/bash
set -e

USAGE="$(basename "$0") [-h] [-r RESOURCE_GROUP] [-s STORAGE_ACCOUNT_NAME] [-c CONTAINER_NAME] [-k KEY] [-l LOCATION] [-e ENVIRONMENT_NAME] [-t ARM_TENANT_ID] [-u ARM_SUBSCRIPTION_ID]
Create infrastructure for Azure using Terraform
where:
    -h   show this help text
    -r   resource group name
    -s   storage account name
    -c   storage account container name
    -k   terraform backend key state
    -l   location resources
    -e   environment name
    -t  tenant id
    -u  subscription id"

OPTIONS=':r:s:c:k:l:e:t:u:'
while getopts $OPTIONS option; do
  case "$option" in
    h) echo "$USAGE"; exit;;
    r) RESOURCE_GROUP_NAME=$OPTARG;;
    s) STORAGE_ACCOUNT_NAME=$OPTARG;;
    c) CONTAINER_NAME=$OPTARG;;
    k) KEY=$OPTARG;;
    l) LOCATION=$OPTARG;;
    e) ENVIRONMENT_NAME=$OPTARG;;
    t) ARM_TENANT_ID=$OPTARG;;
    u) ARM_SUBSCRIPTION_ID=$OPTARG;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$USAGE" >&2; exit 1;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$USAGE" >&2; exit 1;;
  esac
done

# Check mandatory arguments
if [ ! "$RESOURCE_GROUP_NAME" ] || [ ! "$STORAGE_ACCOUNT_NAME" ] || [ ! "$CONTAINER_NAME" ] || [ ! "$KEY" ]  || [ ! "$LOCATION" ] || [ ! "$ENVIRONMENT_NAME" ] || [ ! "$ARM_TENANT_ID" ] || [ ! "$ARM_SUBSCRIPTION_ID" ]; then
  echo "$USAGE" >&2; exit 1
fi

# Login Azure
az login -t $ARM_TENANT_ID -o none

# Change subscription
az account set --subscription $ARM_SUBSCRIPTION_ID -o none

# Create Resource Group
az group create -l $LOCATION -n $RESOURCE_GROUP_NAME -o none

# Create Storage Account
az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME -l $LOCATION -o none

# Create Storage Account blob
az storage container create  --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME -o none

# Create/Select Terraform workspace
WORKSPACE="edeka_$ENVIRONMENT_NAME"
terraform workspace select $WORKSPACE || terraform workspace new $WORKSPACE

pushd deployment
# Initialize deployment
terraform init \
    -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
    -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=$CONTAINER_NAME" \
    -backend-config="key=$KEY"
terraform plan \
  -var-file=terraform-$ENVIRONMENT_NAME-auto.tfvars \
  -input=false \
  -out=tfplan #TODO add json file to github action secrets with params
terraform apply tfplan -auto-approve
popd