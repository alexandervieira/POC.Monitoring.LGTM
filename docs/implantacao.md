# Guia de Implantação - Stack LGTM + LGPD

## 0. Instalação de Ferramentas no Windows 11

### 0.1. Docker Desktop
```powershell
# Download e instalação
# 1. Baixar: https://www.docker.com/products/docker-desktop/
# 2. Executar instalador
# 3. Reiniciar o computador
# 4. Verificar instalação
docker --version
docker-compose --version
```

### 0.2. .NET 10 SDK
```powershell
# Download e instalação
# 1. Baixar: https://dotnet.microsoft.com/download/dotnet/10.0
# 2. Executar instalador dotnet-sdk-10.0-win-x64.exe
# 3. Verificar instalação
dotnet --version
```

### 0.3. Git
```powershell
# Download e instalação
# 1. Baixar: https://git-scm.com/download/win
# 2. Executar instalador Git-2.43.0-64-bit.exe
# 3. Verificar instalação
git --version
```

### 0.4. Terraform
```powershell
# Via Chocolatey (recomendado)
choco install terraform

# Ou manual:
# 1. Baixar: https://www.terraform.io/downloads
# 2. Extrair terraform.exe para C:\terraform
# 3. Adicionar ao PATH: setx PATH "%PATH%;C:\terraform"
# 4. Verificar instalação
terraform --version
```

### 0.5. Azure CLI
```powershell
# Download e instalação
# 1. Baixar: https://aka.ms/installazurecliwindows
# 2. Executar instalador azure-cli.msi
# 3. Verificar instalação
az --version

# Login
az login
```

### 0.6. Google Cloud SDK
```powershell
# Download e instalação
# 1. Baixar: https://cloud.google.com/sdk/docs/install
# 2. Executar instalador GoogleCloudSDKInstaller.exe
# 3. Verificar instalação
gcloud --version

# Login
gcloud auth login
gcloud auth application-default login
```

### 0.7. kubectl
```powershell
# Via Azure CLI
az aks install-cli

# Ou via Chocolatey
choco install kubernetes-cli

# Verificar instalação
kubectl version --client
```

### 0.8. Helm
```powershell
# Via Chocolatey
choco install kubernetes-helm

# Ou manual:
# 1. Baixar: https://github.com/helm/helm/releases
# 2. Extrair helm.exe para C:\helm
# 3. Adicionar ao PATH
# 4. Verificar instalação
helm version
```

### 0.9. k6 (Testes de Carga)
```powershell
# Via Chocolatey
choco install k6

# Ou manual:
# 1. Baixar: https://github.com/grafana/k6/releases
# 2. Extrair k6.exe para C:\k6
# 3. Adicionar ao PATH
# 4. Verificar instalação
k6 version
```

### 0.10. Visual Studio Code (Opcional)
```powershell
# Download e instalação
# 1. Baixar: https://code.visualstudio.com/
# 2. Executar instalador VSCodeUserSetup-x64.exe
# 3. Instalar extensões recomendadas:
#    - C# Dev Kit
#    - Docker
#    - Terraform
#    - Kubernetes
```

### 0.11. Configurar WSL2 (Recomendado)
```powershell
# Habilitar WSL2
wsl --install

# Instalar Ubuntu
wsl --install -d Ubuntu-22.04

# Configurar Docker para usar WSL2
# Docker Desktop > Settings > General > Use WSL 2 based engine
```

## 1. Pré-requisitos

### Ferramentas Necessárias
```bash
# Docker & Docker Compose
docker --version  # >= 24.0
docker-compose --version  # >= 2.20

# .NET SDK
dotnet --version  # >= 10.0

# Terraform
terraform --version  # >= 1.6

# Helm
helm version  # >= 3.12

# kubectl
kubectl version  # >= 1.28

# Azure CLI (para Azure)
az --version  # >= 2.50

# gcloud CLI (para GCP)
gcloud --version  # >= 450.0
```

### Contas Cloud Necessárias

#### Azure
```bash
# Login
az login

# Selecionar subscription
az account list --output table
az account set --subscription "<subscription-id>"

# Verificar
az account show
```

#### Google Cloud Platform
```bash
# Login
gcloud auth login
gcloud auth application-default login

# Criar/selecionar projeto
gcloud projects create poc-lgtm-monitoring --name="POC LGTM Monitoring"
gcloud config set project poc-lgtm-monitoring

# Habilitar APIs necessárias
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable run.googleapis.com
```

## 2. Deploy Local (Desenvolvimento)

### 2.1. Clonar Repositório
```bash
git clone <repo-url>
cd POC.Monitoring.LGTM
```

### 2.2. Subir Stack LGTM Local
```bash
cd backend/scripts-grafana

# Subir todos os serviços
docker-compose -f docker-compose-otel.yml up -d

# Verificar status
docker-compose -f docker-compose-otel.yml ps

# Logs
docker-compose -f docker-compose-otel.yml logs -f
```

### 2.3. Serviços Disponíveis
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **OpenTelemetry Collector**: http://localhost:4317 (OTLP gRPC)
- **OpenTelemetry Collector**: http://localhost:4318 (OTLP HTTP)

### 2.4. Executar Backend API
```bash
cd backend/src/APIContagem

# Restaurar dependências
dotnet restore

# Executar
dotnet run

# API disponível em:
# http://localhost:5000
# https://localhost:5001
```

### 2.5. Executar Frontend
```bash
cd frontend/monitoring-lgtm

# Instalar dependências
npm install

# Executar em modo desenvolvimento
npm run dev

# Frontend disponível em:
# http://localhost:5173
```

### 2.6. Testar Sanitização LGPD
```bash
# Endpoint de teste com dados sensíveis
curl -X POST http://localhost:5000/lgpd/test \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "123.456.789-10",
    "email": "usuario@email.com",
    "telefone": "(11) 98765-4321",
    "cartao": "4111 1111 1111 1111"
  }'

# Verificar logs sanitizados no Grafana
# 1. Acessar http://localhost:3000
# 2. Ir em Explore > Loki
# 3. Query: {service_name="apicontagem"} |= "REDACTED"
```

### 2.7. Configurar Dashboards Grafana
```bash
# 1. Acessar Grafana: http://localhost:3000
# 2. Login: admin/admin
# 3. Importar dashboards:
#    - ASP.NET Core Metrics (ID: 19924)
#    - ASP.NET Core Endpoint (ID: 19925)

# Ou via API:
curl -X POST http://localhost:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{
    "dashboard": {
      "id": null,
      "uid": null,
      "title": "ASP.NET Core Metrics"
    },
    "inputs": [],
    "overwrite": true,
    "pluginId": "grafana-simple-json-datasource"
  }'
```

### 2.8. Executar Testes de Carga
```bash
cd backend/k6

# Executar teste
k6 run load-test.js

# Resultado esperado:
# - 1000 VUs
# - 10 minutos de duração
# - < 500ms p95 latency
# - < 1% error rate
```

## 3. Deploy Azure (Terraform)

### 3.1. Configurar Variáveis de Ambiente
```bash
# Criar arquivo terraform.tfvars
cd terraform/azure/environments/dev

cat > terraform.tfvars <<EOF
project_name = "lgtm"
environment = "dev"
location = "eastus"

# AKS
aks_node_count = 3
aks_node_size = "Standard_D4s_v3"

# PostgreSQL
postgresql_sku = "B_Standard_B1ms"
postgresql_storage_mb = 32768

# Tags
tags = {
  Project = "POC-LGTM"
  Environment = "Development"
  ManagedBy = "Terraform"
}
EOF
```

### 3.2. Inicializar Terraform
```bash
# Inicializar
terraform init

# Validar configuração
terraform validate

# Planejar mudanças
terraform plan -out=tfplan
```

### 3.3. Aplicar Infraestrutura
```bash
# Aplicar
terraform apply tfplan

# Ou aplicar diretamente (com confirmação)
terraform apply

# Aguardar ~15-20 minutos para provisionamento completo
```

### 3.4. Configurar kubectl
```bash
# Obter credenciais do AKS
az aks get-credentials \
  --resource-group rg-lgtm-dev \
  --name aks-lgtm-dev

# Verificar conexão
kubectl get nodes
kubectl get pods -n monitoring
```

### 3.5. Deploy Stack LGTM no AKS
```bash
cd k8s/helm/lgtm-stack

# Adicionar repositórios Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar stack LGTM
helm install lgtm-stack . \
  --namespace monitoring \
  --create-namespace \
  --values values/dev.yaml

# Verificar instalação
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 3.6. Obter URLs de Acesso
```bash
# Outputs do Terraform
terraform output

# Grafana URL
terraform output grafana_url

# OpenTelemetry Collector Endpoint
terraform output otel_collector_endpoint

# Frontend URL
terraform output frontend_url

# Backend API URL
terraform output backend_api_url
```

### 3.7. Configurar DNS (Opcional)
```bash
# Obter IP público do Ingress
kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Configurar registro DNS
# grafana.seudominio.com -> <IP_PUBLICO>
```

## 4. Deploy GCP (Terraform)

### 4.1. Configurar Variáveis de Ambiente
```bash
cd terraform/gcp/environments/dev

cat > terraform.tfvars <<EOF
project_id = "poc-lgtm-monitoring"
region = "us-central1"
environment = "dev"

# GKE
gke_node_count = 3
gke_machine_type = "e2-standard-4"

# Cloud SQL
db_tier = "db-f1-micro"
db_disk_size = 10

# Tags
labels = {
  project = "poc-lgtm"
  environment = "dev"
  managed-by = "terraform"
}
EOF
```

### 4.2. Inicializar Terraform
```bash
# Inicializar
terraform init

# Validar
terraform validate

# Planejar
terraform plan -out=tfplan
```

### 4.3. Aplicar Infraestrutura
```bash
# Aplicar
terraform apply tfplan

# Aguardar ~15-20 minutos
```

### 4.4. Configurar kubectl
```bash
# Obter credenciais do GKE
gcloud container clusters get-credentials dev-lgtm-cluster \
  --region us-central1 \
  --project poc-lgtm-monitoring

# Verificar
kubectl get nodes
kubectl get pods -n monitoring
```

### 4.5. Deploy Stack LGTM no GKE
```bash
cd k8s/helm/lgtm-stack

# Instalar stack
helm install lgtm-stack . \
  --namespace monitoring \
  --create-namespace \
  --values values/dev.yaml

# Verificar
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 4.6. Obter URLs de Acesso
```bash
# Outputs
terraform output

# Grafana Service
terraform output grafana_service

# OpenTelemetry Collector
terraform output otel_collector_endpoint
```

## 5. Configuração de Monitoramento

### 5.1. Configurar Data Sources no Grafana
```bash
# Acessar Grafana
# Azure: https://<grafana-url>
# GCP: http://<grafana-ip>:3000
# Local: http://localhost:3000

# Login: admin/admin (trocar senha no primeiro acesso)

# Adicionar Data Sources:
# 1. Prometheus: http://prometheus:9090
# 2. Loki: http://loki:3100
# 3. Tempo: http://tempo:3200
```

### 5.2. Importar Dashboards
```bash
# Via UI:
# 1. Dashboards > Import
# 2. Inserir ID: 19924 (ASP.NET Core Metrics)
# 3. Selecionar Prometheus data source
# 4. Import

# Repetir para:
# - ID 19925: ASP.NET Core Endpoint
```

### 5.3. Configurar Alertas
```bash
# Criar regra de alerta para alta latência
cat > alert-high-latency.yaml <<EOF
apiVersion: 1
groups:
  - name: api-alerts
    interval: 1m
    rules:
      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_server_duration_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alta latência detectada"
          description: "P95 latency está acima de 500ms"
EOF

# Aplicar no Prometheus
kubectl create configmap prometheus-alerts \
  --from-file=alert-high-latency.yaml \
  -n monitoring
```

## 6. Verificação e Testes

### 6.1. Verificar Pods
```bash
# Todos os pods devem estar Running
kubectl get pods -n monitoring

# Logs de um pod específico
kubectl logs -n monitoring <pod-name> -f
```

### 6.2. Testar Conectividade
```bash
# Testar API
curl https://<backend-url>/health

# Testar OpenTelemetry Collector
curl http://<otel-collector-url>:13133/

# Testar Grafana
curl https://<grafana-url>/api/health
```

### 6.3. Validar Sanitização LGPD
```bash
# Enviar requisição com dados sensíveis
curl -X POST https://<backend-url>/lgpd/test \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "123.456.789-10",
    "email": "teste@email.com"
  }'

# Verificar logs no Grafana Loki
# Query: {service_name="apicontagem"} |= "REDACTED"
# Deve mostrar: ***CPF-REDACTED*** e ***EMAIL-REDACTED***
```

### 6.4. Executar Testes de Carga
```bash
# Atualizar URL no script k6
cd backend/k6

# Editar load-test.js
# const BASE_URL = 'https://<backend-url>';

# Executar teste
k6 run load-test.js

# Monitorar no Grafana durante o teste
```

## 7. Ambientes (Dev, Staging, Prod)

### 7.1. Deploy em Staging
```bash
# Azure
cd terraform/azure/environments/staging
terraform init
terraform apply

# GCP
cd terraform/gcp/environments/stage
terraform init
terraform apply

# Helm
helm install lgtm-stack . \
  --namespace monitoring \
  --values values/stage.yaml
```

### 7.2. Deploy em Produção
```bash
# Azure
cd terraform/azure/environments/prod
terraform init
terraform apply

# GCP
cd terraform/gcp/environments/prod
terraform init
terraform apply

# Helm
helm install lgtm-stack . \
  --namespace monitoring \
  --values values/prod.yaml
```

### 7.3. Diferenças entre Ambientes

| Recurso | Dev | Staging | Prod |
|---------|-----|---------|------|
| AKS/GKE Nodes | 3 | 3 | 5 |
| Node Size | Standard_D4s_v3 | Standard_D4s_v3 | Standard_D8s_v3 |
| PostgreSQL | B_Standard_B1ms | GP_Standard_D2s_v3 | GP_Standard_D4s_v3 |
| Retenção Logs | 30d | 60d | 90d |
| Backup | Diário | Diário | Horário |
| HA | Não | Sim | Sim |

## 8. Manutenção

### 8.1. Atualizar Stack LGTM
```bash
# Atualizar repositórios Helm
helm repo update

# Atualizar release
helm upgrade lgtm-stack . \
  --namespace monitoring \
  --values values/dev.yaml

# Verificar
kubectl rollout status deployment -n monitoring
```

### 8.2. Backup e Restore
```bash
# Backup Grafana dashboards
kubectl exec -n monitoring grafana-0 -- \
  grafana-cli admin export-dashboards > dashboards-backup.json

# Backup PostgreSQL
kubectl exec -n default postgres-0 -- \
  pg_dump -U postgres apicontagem > db-backup.sql

# Restore
kubectl exec -i -n default postgres-0 -- \
  psql -U postgres apicontagem < db-backup.sql
```

### 8.3. Limpeza de Dados Antigos
```bash
# Verificar uso de storage
kubectl exec -n monitoring loki-0 -- df -h

# Forçar compactação (Loki)
kubectl exec -n monitoring loki-0 -- \
  curl -X POST http://localhost:3100/loki/api/v1/delete?query={job="apicontagem"}&start=0&end=<timestamp>

# Verificar lifecycle policies
# Azure Blob Storage: Automático via Terraform
# GCS: Automático via Terraform
```

### 8.4. Monitorar Custos
```bash
# Azure
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --query "[?contains(instanceName, 'lgtm')]"

# GCP
gcloud billing accounts list
gcloud billing projects describe poc-lgtm-monitoring
```

## 9. Troubleshooting

### 9.1. Pods não iniciam
```bash
# Verificar eventos
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Descrever pod
kubectl describe pod -n monitoring <pod-name>

# Logs
kubectl logs -n monitoring <pod-name> --previous
```

### 9.2. OpenTelemetry Collector não recebe dados
```bash
# Verificar configuração
kubectl get configmap -n monitoring otel-collector-config -o yaml

# Testar endpoint
kubectl port-forward -n monitoring svc/otel-collector 4317:4317
curl http://localhost:4317

# Verificar logs
kubectl logs -n monitoring deployment/otel-collector -f
```

### 9.3. Grafana não mostra dados
```bash
# Verificar data sources
kubectl exec -n monitoring grafana-0 -- \
  curl http://localhost:3000/api/datasources

# Testar conectividade
kubectl exec -n monitoring grafana-0 -- \
  curl http://prometheus:9090/api/v1/query?query=up

# Verificar logs
kubectl logs -n monitoring deployment/grafana -f
```

### 9.4. Alta latência
```bash
# Verificar recursos
kubectl top nodes
kubectl top pods -n monitoring

# Escalar deployment
kubectl scale deployment -n monitoring otel-collector --replicas=3

# Verificar HPA
kubectl get hpa -n monitoring
```

## 10. Segurança

### 10.1. Configurar TLS/SSL
```bash
# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Criar ClusterIssuer
cat > letsencrypt-prod.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@seudominio.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f letsencrypt-prod.yaml
```

### 10.2. Configurar RBAC
```bash
# Criar service account
kubectl create serviceaccount monitoring-sa -n monitoring

# Criar role
cat > monitoring-role.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: monitoring-role
  namespace: monitoring
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
EOF

kubectl apply -f monitoring-role.yaml

# Criar role binding
kubectl create rolebinding monitoring-binding \
  --role=monitoring-role \
  --serviceaccount=monitoring:monitoring-sa \
  -n monitoring
```

### 10.3. Secrets Management
```bash
# Criar secret para Grafana
kubectl create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=<senha-forte> \
  -n monitoring

# Criar secret para PostgreSQL
kubectl create secret generic postgres-credentials \
  --from-literal=username=postgres \
  --from-literal=password=<senha-forte> \
  -n default
```

## 11. CI/CD (Opcional)

### 11.1. GitHub Actions - Azure
```yaml
# .github/workflows/deploy-azure.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Apply
        run: |
          cd terraform/azure/environments/prod
          terraform init
          terraform apply -auto-approve
      
      - name: Deploy to AKS
        run: |
          az aks get-credentials --resource-group rg-lgtm-prod --name aks-lgtm-prod
          helm upgrade --install lgtm-stack k8s/helm/lgtm-stack \
            --namespace monitoring \
            --values k8s/helm/lgtm-stack/values/prod.yaml
```

### 11.2. GitHub Actions - GCP
```yaml
# .github/workflows/deploy-gcp.yml
name: Deploy to GCP

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: GCP Auth
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Terraform Apply
        run: |
          cd terraform/gcp/environments/prod
          terraform init
          terraform apply -auto-approve
      
      - name: Deploy to GKE
        run: |
          gcloud container clusters get-credentials prod-lgtm-cluster --region us-central1
          helm upgrade --install lgtm-stack k8s/helm/lgtm-stack \
            --namespace monitoring \
            --values k8s/helm/lgtm-stack/values/prod.yaml
```

## 12. Referências

### Documentação Oficial
- [Grafana Loki](https://grafana.com/docs/loki/latest/)
- [Grafana Tempo](https://grafana.com/docs/tempo/latest/)
- [Prometheus](https://prometheus.io/docs/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Comunidade
- [Grafana Community](https://community.grafana.com/)
- [OpenTelemetry Community](https://cloud-native.slack.com/)
- [CNCF Slack](https://slack.cncf.io/)

---

**Próximos Passos:**
1. Revisar [Visão Geral](visao_geral.md) para entender custos e decisões arquiteturais
2. Configurar ambiente local seguindo seção 2
3. Deploy em cloud (Azure ou GCP) seguindo seções 3 ou 4
4. Configurar dashboards e alertas (seção 5)
5. Executar testes de carga (seção 6.4)
