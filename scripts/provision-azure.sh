#!/usr/bin/env bash
# One-time Azure setup. Prereq: Azure CLI, `az login`. Run from anywhere.
# ACR and App Service names must be globally unique -> edit the defaults.
set -euo pipefail
RG="${RG:-codealpha-rg}"
LOCATION="${LOCATION:-westeurope}"
ACR="${ACR:-codealphaacr$RANDOM}"          # lowercase letters/digits only
PLAN="${PLAN:-codealpha-plan}"
APP="${APP:-codealpha-cicd-app}"

az group create -n "$RG" -l "$LOCATION"
az acr create -g "$RG" -n "$ACR" --sku Basic
az appservice plan create -g "$RG" -n "$PLAN" --is-linux --sku B1

# Placeholder image so the app exists; the pipeline replaces it on first run
az webapp create -g "$RG" -p "$PLAN" -n "$APP" --deployment-container-image-name mcr.microsoft.com/appsvc/staticsite:latest

# Pull from ACR using the app's managed identity (no admin password)
az webapp identity assign -g "$RG" -n "$APP"
PRINCIPAL=$(az webapp identity show -g "$RG" -n "$APP" --query principalId -o tsv)
ACR_ID=$(az acr show -n "$ACR" --query id -o tsv)
az role assignment create --assignee "$PRINCIPAL" --role AcrPull --scope "$ACR_ID"
az webapp config set -g "$RG" -n "$APP" --generic-configurations '{"acrUseManagedIdentityCreds": true}'

az webapp config appsettings set -g "$RG" -n "$APP" --settings WEBSITES_PORT=8080
az webapp config set -g "$RG" -n "$APP" --health-check-path /health 2>/dev/null || \
  az resource update -g "$RG" -n "$APP/config/web" --resource-type Microsoft.Web/sites/config --set properties.healthCheckPath=/health

# Logs for monitoring
az webapp log config -g "$RG" -n "$APP" --docker-container-logging filesystem

echo
echo "ACR name: $ACR    App name: $APP    URL: https://$APP.azurewebsites.net"
echo "Next: create the two service connections in Azure DevOps and update variables in azure-pipelines.yml"
