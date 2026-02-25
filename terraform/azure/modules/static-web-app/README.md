# Azure Static Web App - Frontend React

Módulo Terraform para provisionar Azure Static Web App para o frontend React + TypeScript + Vite.

## Recursos Criados

- Azure Static Web App (Free tier)
- Custom domain (opcional)

## Uso

```hcl
module "static_web_app" {
  source = "../../modules/static-web-app"
  
  environment         = "dev"
  location            = "East US 2"
  resource_group_name = "rg-lgtm-dev"
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = local.tags
}
```

## Deploy do Frontend

### 1. Via GitHub Actions

```yaml
name: Deploy Static Web App

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Deploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/frontend/monitoring-lgtm"
          output_location: "dist"
```

### 2. Via Azure CLI

```bash
# Obter API key
terraform output -raw frontend_api_key

# Build do frontend
cd frontend/monitoring-lgtm
npm install
npm run build

# Deploy
az staticwebapp deploy \
  --name swa-lgtm-dev \
  --resource-group rg-lgtm-dev \
  --app-location . \
  --output-location dist \
  --api-token <API_KEY>
```

### 3. Via SWA CLI

```bash
# Instalar SWA CLI
npm install -g @azure/static-web-apps-cli

# Deploy
cd frontend/monitoring-lgtm
swa deploy \
  --deployment-token <API_KEY> \
  --app-location . \
  --output-location dist
```

## Configuração do Frontend

### Environment Variables

Criar arquivo `.env.production`:

```env
VITE_API_URL=https://ca-apicontagem-dev.azurecontainerapps.io
VITE_GRAFANA_URL=http://<grafana-public-ip>
```

### staticwebapp.config.json

```json
{
  "navigationFallback": {
    "rewrite": "/index.html"
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html"
    }
  }
}
```

## Custos

| Tier | Bandwidth | Custom Domains | Custo/mês |
|------|-----------|----------------|-----------|
| Free | 100 GB | 2 | $0 |
| Standard | 100 GB | 5 | $9 |

## Outputs

- `url`: URL pública do Static Web App
- `api_key`: Token para deploy (sensitive)
- `default_host_name`: Hostname padrão
