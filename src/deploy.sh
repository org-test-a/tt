#!/bin/bash
set -e

USAGE="$(basename "$0") [-h] [-r RESOURCE_GROUP] [-s STORAGE_ACCOUNT_NAME] [-c CONTAINER_NAME] [-k KEY] [-l LOCATION] [-e ENVIRONMENT_NAME]
Create infrastructure for Azure using Terraform
where:
    -h  show this help text
    -r  resource group name
    -s  storage account name
    -c  storage account container name
    -k  terraform backend key state
    -l  location resources
    -e  environment name"

OPTIONS=':r:s:c:k:l:e:'
while getopts $OPTIONS option; do
  case "$option" in
    h) echo "$USAGE"; exit;;
    r) RESOURCE_GROUP_NAME=$OPTARG;;
    s) STORAGE_ACCOUNT_NAME=$OPTARG;;
    c) CONTAINER_NAME=$OPTARG;;
    k) KEY=$OPTARG;;
    l) LOCATION=$OPTARG;;
    e) ENVIRONMENT_NAME=$OPTARG;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$USAGE" >&2; exit 1;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$USAGE" >&2; exit 1;;
  esac
done

# Check mandatory arguments
if [ ! "$RESOURCE_GROUP_NAME" ] || [ ! "$STORAGE_ACCOUNT_NAME" ] || [ ! "$CONTAINER_NAME" ] || [ ! "$KEY" ]  || [ ! "$LOCATION" ] || [ ! "$ENVIRONMENT_NAME" ]; then
  echo "$USAGE" >&2; exit 1
fi

# Create Resource Group if not exist
az group list -o tsv | grep $RESOURCE_GROUP_NAME -q || az group create -l $LOCATION -n $RESOURCE_GROUP_NAME -o none

# Create Storage Account if not exist
az storage account list -g $RESOURCE_GROUP_NAME -o tsv | grep $STORAGE_ACCOUNT_NAME -q || az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME -l $LOCATION -o none

# Create Storage Account blob if not exist
az storage container exists --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME -o tsv | grep True -q || az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME -o none

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

# Extract tfvars file from secrets by environment
echo $SECRET | base64 -d > tfvars_$ENVIRONMENT_NAME

terraform plan \
  -var-file=tfvars_$ENVIRONMENT_NAME \
  -input=false \
  -out=tfplan_$ENVIRONMENT_NAME

terraform apply tfplan_$ENVIRONMENT_NAME -auto-approve
popd
