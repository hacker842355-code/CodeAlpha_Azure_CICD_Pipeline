#!/usr/bin/env bash
# Lists recent pipeline runs and tails app logs. Prereq: az extension add --name azure-devops
# Usage: ORG=https://dev.azure.com/<org> PROJECT=<project> APP=<webapp> RG=<rg> scripts/monitor-pipeline.sh
set -euo pipefail
: "${ORG:?set ORG}" "${PROJECT:?set PROJECT}"
az pipelines runs list --org "$ORG" --project "$PROJECT" --top 10 \
  --query "[].{id:id, status:status, result:result, branch:sourceBranch, finished:finishTime}" -o table
if [ -n "${APP:-}" ] && [ -n "${RG:-}" ]; then
  echo "--- App Service logs (Ctrl+C to stop) ---"
  az webapp log tail -g "$RG" -n "$APP"
fi
