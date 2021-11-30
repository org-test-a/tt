# Infrastructure deployment documentation

## Script for deployment
Script invoke all steps to create infrastructure for Azure.

### Steps deploy
- pre-deployment: Create resource group with storage account and container, to save backend terraform state

- deployment: Create AKS and install and configure all Helms chats
