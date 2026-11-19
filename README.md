# CodeAlpha_Azure_CICD_Pipeline — Task 1: CI/CD Pipeline using Azure

A tiny Node.js web app (zero npm dependencies) delivered by **Azure Pipelines → Azure Container Registry → Azure App Service (Linux container)**.

## Flow
```
git push main → Azure Pipelines
  Stage Build : npm test (JUnit results published) → docker build → push to ACR (tags: BuildId, latest)
  Stage Deploy: AzureWebAppContainer → App Service pulls image from ACR → smoke test GET /health
```

## Task requirements → where they are met
| Requirement | Implementation |
|---|---|
| Automated CI/CD with Azure Pipelines | `azure-pipelines.yml` (2 stages, PR builds run tests only) |
| Azure Container Registry for storage | `Docker@2 buildAndPush` + `scripts/provision-azure.sh` creates ACR |
| Auto-deploy to App Service | `AzureWebAppContainer@1` in a `deployment` job bound to the `production` Environment |
| Monitor the pipeline | test results tab, `scripts/monitor-pipeline.sh`, App Service health check + log tail, see below |
| Learn key DevOps concepts | stages, service connections, environments/approvals, immutable image tags, health-gated release |

## Prerequisites
- Azure subscription, Azure CLI (`az login`), an Azure DevOps organization + project
- Node 20+ for local runs (Docker optional)

## Local run and tests (from this folder)
```bash
npm test          # 4 tests with the built-in node:test runner
npm start         # http://localhost:8080  (/, /health, /api/info)
docker build -t codealpha-cicd-app . && docker run -p 8080:8080 codealpha-cicd-app
```

## Azure setup (one time)
1. `./scripts/provision-azure.sh` — creates resource group, ACR (Basic), Linux App Service plan (B1), web app, `AcrPull` role for the app's managed identity, port setting, `/health` health check, log config. Override names with env vars (`ACR`, `APP`, `RG`, `LOCATION`); ACR/App names must be globally unique.
2. Push this folder to a repo (GitHub or Azure Repos) named `CodeAlpha_Azure_CICD_Pipeline`.
3. Azure DevOps → Project settings → **Service connections**:
   - *Docker Registry → Azure Container Registry* → name it `acr-service-connection`
   - *Azure Resource Manager* → name it `azure-rm-connection`
4. Edit the `variables:` block at the top of `azure-pipelines.yml` (`acrName`, `webAppName`, connection names).
5. Pipelines → New pipeline → existing YAML → `azure-pipelines.yml` → Run.
6. (Recommended) Pipelines → Environments → `production` → add **Approvals and checks**.

Open `https://<webAppName>.azurewebsites.net/api/info` — `build` should match the pipeline run number.

## Monitoring
- **Pipeline:** run summary → *Tests* tab; Project settings → Notifications for failure emails; Analytics → pipeline pass rate/duration.
- **CLI:** `ORG=https://dev.azure.com/<org> PROJECT=<proj> APP=<webapp> RG=codealpha-rg ./scripts/monitor-pipeline.sh` (needs `az extension add --name azure-devops`).
- **App:** App Service *Health check* (`/health`), *Log stream*, `az webapp log tail`.

## Roll back
Redeploy an earlier image tag: `az webapp config container set -g <rg> -n <app> --container-image-name <acr>.azurecr.io/codealpha-cicd-app:<oldBuildId>`.

## Common errors
| Error | Fix |
|---|---|
| `No hosted parallelism has been purchased` | New Azure DevOps orgs must request the free grant (aka.ms/azpipelines-parallelism-request) or use a self-hosted agent |
| App shows "Application Error" / 503 | `WEBSITES_PORT` must be 8080; check `az webapp log tail` |
| `unauthorized` pulling image | Re-run the AcrPull role assignment in `provision-azure.sh`; wait a few minutes |
| Service connection not found | Names in `variables:` must match exactly |

## Known limitations
Not executed against a real Azure subscription (see root `TESTING_REPORT.md`). No staging slot, IaC (Bicep/Terraform), or Application Insights; a good next step.
