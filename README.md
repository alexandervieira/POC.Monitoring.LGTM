# POC Monitoring LGTM + LGPD

Prova de conceito de observabilidade com Stack LGTM (Loki + Grafana + Tempo + Mimir/Prometheus) + OpenTelemetry para aplicações .NET 10, com conformidade LGPD através de sanitização de dados sensíveis e retenção controlada.

## 📚 Documentação

- **[Visão Geral](docs/visao_geral.md)** - Comparação Stack LGTM vs Application Insights, custos, LGPD e decisões arquiteturais
- **[Guia de Implantação](docs/implantacao.md)** - Instalação de ferramentas, deploy local, GCP, Azure e Kubernetes
- **[Backend API](backend/README.md)** - Documentação da API .NET 10 com OpenTelemetry e exemplos de dashboards
- **[Frontend Dashboard](frontend/monitoring-lgtm/README.md)** - Dashboard React + TypeScript + Vite para visualização
- **[Terraform Azure](terraform/azure/README.md)** - Infraestrutura como código para Azure com AKS
- **[Terraform GCP](terraform/gcp/)** - Infraestrutura como código para GCP com GKE

## 🎯 Visão Geral

### Stack LGTM
Solução open-source de observabilidade que oferece:
- **Loki**: Agregação de logs com baixo custo
- **Grafana**: Visualização unificada de métricas, logs e traces
- **Tempo**: Distributed tracing para análise de performance
- **Prometheus**: Métricas de aplicação e infraestrutura
- **OpenTelemetry Collector**: Pipeline de telemetria com sanitização LGPD

### Conformidade LGPD (Implementado)
- ✅ **4 Camadas de Sanitização**: Aplicação → OTel Collector → Storage → Lifecycle
- ✅ Sanitização automática de CPF, email, telefone, cartão, CNPJ e JWT
- ✅ Anonimização com SHA256 hash para identificação de usuários
- ✅ Retenção de 90 dias com limpeza automática (Azure Blob + GCS)
- ✅ API de exclusão para direito ao esquecimento
- ✅ Criptografia AES-256 para dados sensíveis

### Decisão Arquitetural: Grafana Self-Hosted
**✅ Implementado:** Grafana self-hosted no AKS (Azure) e GKE (GCP)

**Justificativa:**
- 💰 Azure Managed Grafana adiciona $100/mês sem reduzir complexidade
- 🔒 Controle total sobre LGPD e sanitização
- 🎯 Toda stack LGTM no mesmo cluster
- 🔧 Plugins ilimitados e customizações completas

### Comparação de Custos (100GB/mês)
| Solução | Custo | Economia |
|---------|-------|----------|
| Azure Self-Hosted (Implementado) | $161/mês | Baseline |
| GCP Self-Hosted (Implementado) | $216/mês | -25% |
| Azure Managed Grafana | $261/mês | -38% ❌ |
| Application Insights | $230/mês | -30% |

**Break-even**: Stack LGTM compensa a partir de 100GB/mês (economia de 30-80%)

## 🏗️ Arquitetura

### Fluxo de Dados com LGPD
```
┌─────────────────┐
│   API .NET 10   │
│  + OpenTelemetry│
│  + SensitiveData│  ◄── Camada 1: Sanitização na aplicação
│    LogProcessor │
└────────┬────────┘
         │ OTLP
         ▼
┌─────────────────┐
│  OTel Collector │
│  + Transform    │  ◄── Camada 2: Sanitização no collector
│  + Attributes   │      (CPF, Email, JWT, Headers)
└────────┬────────┘
         │
    ┌────┴────┬────────┬──────────┐
    ▼         ▼        ▼          ▼
┌──────┐ ┌──────┐ ┌────────┐ ┌─────────┐
│ Loki │ │Tempo │ │Prometheus│ │Grafana │
│(logs)│ │(trace)│ │(metrics) │ │ (UI)   │
│ 90d  │ │ 90d  │ │  90d     │ │Self-   │  ◄── Camada 3: Retenção
└───┬──┘ └───┬──┘ └────┬─────┘ │Hosted  │
    │        │         │        └─────────┘
    ▼        ▼         ▼
┌────────────────────────────┐
│  Azure Blob / GCS          │
│  Lifecycle: 90 dias        │  ◄── Camada 4: Storage lifecycle
└────────────────────────────┘
```

### Componentes Implementados
- **Backend**: API REST .NET 10 + ASP.NET Core + PostgreSQL (Container Apps / Cloud Run)
- **Frontend**: React + TypeScript + Vite (Azure Static Web App / Firebase Hosting)
- **Observabilidade**: OpenTelemetry + Stack LGTM (self-hosted no AKS/GKE)
- **Infraestrutura**: Terraform (Azure + GCP) + Kubernetes (AKS/GKE)
- **LGPD**: 4 camadas de sanitização + retenção de 90 dias

## 🛠️ Tecnologias

### Backend
- **.NET 10** - Framework de aplicação
- **ASP.NET Core** - API REST
- **OpenTelemetry** - Instrumentação de telemetria
- **PostgreSQL** - Banco de dados relacional
- **Entity Framework Core** - ORM

### Observabilidade
- **OpenTelemetry Collector** - Pipeline com sanitização LGPD
- **Grafana Loki** - Agregação de logs (90d retention)
- **Grafana Tempo** - Distributed tracing (90d retention)
- **Prometheus** - Métricas de aplicação (90d retention)
- **Grafana** - Visualização (self-hosted no AKS/GKE)

### Frontend
- **React 18** - Framework UI
- **TypeScript** - Tipagem estática
- **Vite** - Build tool
- **Recharts** - Gráficos e visualizações

### Infraestrutura
- **Docker** - Containerização
- **Kubernetes** - Orquestração (AKS/GKE)
- **Terraform** - Infrastructure as Code (Azure + GCP)
- **Helm** - Package manager para Kubernetes
- **k6** - Testes de carga

### Cloud Providers
- **Microsoft Azure** - AKS, Blob Storage, PostgreSQL, Container Apps, Static Web App
- **Google Cloud Platform** - GKE, Cloud Storage, Cloud SQL, Cloud Run, Firebase Hosting

## 📁 Estrutura de Pastas

```
POC.Monitoring.LGTM/
├── backend/                          # API .NET 10
│   ├── src/
│   │   └── APIContagem/
│   │       ├── Program.cs            # Configuração OpenTelemetry
│   │       ├── Logging/
│   │       │   ├── SensitiveDataLogProcessor.cs
│   │       │   └── SensitiveDataRedactor.cs
│   │       └── GDPR/
│   │           ├── UserHashService.cs
│   │           └── UserMapping.cs
│   ├── scripts-grafana/
│   │   ├── docker-compose-otel.yml   # Stack LGTM local
│   │   ├── otel-collector-config.yaml
│   │   ├── loki-config.yaml
│   │   ├── tempo-config.yaml
│   │   └── prometheus.yml
│   └── k6/
│       └── load-test.js              # Testes de carga
│
├── frontend/                         # Dashboard React
│   └── monitoring-lgtm/
│       ├── src/
│       ├── package.json
│       └── vite.config.ts
│
├── docs/                             # Documentação
│   ├── visao_geral.md                # Comparação e custos
│   └── implantacao.md                # Guia de deploy
│
├── k8s/                              # Kubernetes manifests
│   ├── configmaps/
│   │   └── alloy-config.yaml         # Configuração Alloy
│   └── helm/
│       └── lgtm-stack/
│           ├── Chart.yaml
│           └── values/
│               ├── dev.yaml
│               ├── stage.yaml
│               └── prod.yaml
│
├── scripts/                          # Scripts de automação
│   ├── deploy-backend.sh
│   ├── deploy-frontend.sh
│   ├── deploy-terraform.sh
│   ├── deploy-terraform-validate.sh
│   ├── init-terraform.sh
│   ├── setup-monitoring.sh
│   ├── validate-all-environments.sh
│   └── generate-terraform-docs.sh
│
└── terraform/                        # Infrastructure as Code
    ├── azure/                        # IaC Azure (Implementado)
    │   ├── environments/
    │   │   ├── dev/
    │   │   ├── staging/
    │   │   └── prod/
    │   └── modules/
    │       ├── network/              # VNet, Subnets, DNS
    │       ├── aks/                  # Kubernetes cluster
    │       ├── storage/              # Blob Storage (90d lifecycle)
    │       ├── postgresql/           # Flexible Server
    │       ├── container-apps/       # Backend API
    │       ├── static-web-app/       # Frontend React
    │       └── monitoring/           # LGTM + OTel Collector
    └── gcp/                          # IaC GCP (Implementado)
        ├── environments/
        │   ├── dev/
        │   ├── stage/
        │   └── prod/
        └── modules/
            ├── networking/           # VPC, Subnets
            ├── gke/                  # Kubernetes cluster
            ├── cloud-storage/        # GCS buckets (90d lifecycle)
            ├── cloud-sql/            # PostgreSQL
            ├── cloud-run/            # Backend API
            ├── firebase-hosting/     # Frontend React
            └── monitoring/           # LGTM + OTel Collector
```

## 🚀 Quick Start

### 1. Pré-requisitos
```bash
# Windows 11
docker --version        # >= 24.0
dotnet --version        # >= 10.0
terraform --version     # >= 1.6
helm --version          # >= 3.12
```

### 2. Executar Localmente
```bash
# Clonar repositório
git clone <repo-url>
cd POC.Monitoring.LGTM/backend

# Subir stack LGTM
cd scripts-grafana
docker-compose -f docker-compose-otel.yml up -d

# Executar API
cd ../src/APIContagem
dotnet run

# Acessar Grafana
# http://localhost:3000 (admin/admin)
```

### 3. Testar Sanitização LGPD
```bash
# Endpoint com dados sensíveis
curl -X POST http://localhost:5000/lgpd/test \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "123.456.789-10",
    "email": "user@email.com",
    "telefone": "(11) 98765-4321"
  }'

# Verificar logs sanitizados no Grafana Loki
# {service_name="apicontagem"} |= "REDACTED"
```

### 4. Deploy em Produção (Azure)
```bash
# Azure (Terraform)
cd terraform/azure/environments/dev
terraform init
terraform plan
terraform apply

# Configurar kubectl
az aks get-credentials --resource-group rg-lgtm-dev --name aks-lgtm-dev

# Verificar pods
kubectl get pods -n monitoring

# Outputs
terraform output grafana_url
terraform output otel_collector_endpoint
terraform output frontend_url
```

### 5. Deploy em Produção (GCP)
```bash
# GCP (Terraform)
cd terraform/gcp/environments/dev
terraform init
terraform plan
terraform apply

# Configurar kubectl
gcloud container clusters get-credentials dev-lgtm-cluster --region us-central1

# Verificar pods
kubectl get pods -n monitoring

# Outputs
terraform output grafana_service
terraform output otel_collector_endpoint
```

## 📊 Dashboards Grafana

Importe os seguintes dashboards:
- **[ASP.NET Core Metrics - ID 19924](https://grafana.com/grafana/dashboards/19924)** - Visão geral de requisições
- **[ASP.NET Core Endpoint - ID 19925](https://grafana.com/grafana/dashboards/19925)** - Telemetria por endpoint

## 🔒 Conformidade LGPD (4 Camadas)

### Camada 1: Aplicação (.NET)
```csharp
// SensitiveDataLogProcessor + IncludeFormattedMessage=false
builder.Logging.AddOpenTelemetry(options => {
    options.IncludeFormattedMessage = false;
    options.ParseStateValues = false;
    options.AddProcessor(new SensitiveDataLogProcessor());
});
```

### Camada 2: OpenTelemetry Collector
```yaml
processors:
  transform/logs:
    log_statements:
      - replace_pattern(body, "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "***CPF-REDACTED***")
      - replace_all_patterns(attributes, "value", "...", "***REDACTED***")
  attributes/delete:
    actions:
      - key: http.request.header.authorization
        action: delete
```

### Camada 3: Retenção (Loki/Tempo/Prometheus)
- Loki: 90 dias (compactor enabled)
- Tempo: 90 dias (block_retention: 2160h)
- Prometheus: 90 dias (retention: 90d)

### Camada 4: Storage Lifecycle
- Azure Blob Storage: Lifecycle policy (90 dias)
- Google Cloud Storage: Lifecycle rule (90 dias)

### Dados Sanitizados
- CPF: `123.456.789-10` → `***CPF-REDACTED***`
- Email: `user@email.com` → `***EMAIL-REDACTED***`
- Telefone: `(11) 98765-4321` → `***PHONE-REDACTED***`
- Cartão: `4111 1111 1111 1111` → `***CARD-REDACTED***`
- CNPJ: `12.345.678/0001-90` → `***CNPJ-REDACTED***`
- JWT: `eyJhbGci...` → `***JWT-REDACTED***`

### Direito ao Esquecimento
```bash
# Excluir dados de usuário
curl -X DELETE http://localhost:5000/gdpr/user/123.456.789-10
```

## 📈 Monitoramento

### Métricas Disponíveis
- Taxa de requisições (req/s)
- Latência (p50, p95, p99)
- Taxa de erros (4xx, 5xx)
- Uso de CPU e memória
- Conexões de banco de dados

### Logs Estruturados (Sanitizados)
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "Information",
  "message": "Usuário ***CPF-REDACTED*** acessou",
  "service": "apicontagem",
  "trace_id": "abc123",
  "span_id": "def456"
}
```

### Distributed Tracing
- Rastreamento end-to-end de requisições
- Análise de latência por componente
- Identificação de gargalos

## 🧪 Testes de Carga

```bash
# Executar teste k6
cd backend/k6
k6 run load-test.js

# Resultado esperado:
# - 1000 VUs
# - 10 minutos de duração
# - < 500ms p95 latency
# - < 1% error rate
```

## 💰 Estimativa de Custos (Implementado)

| Volume/mês | Azure Self-Hosted | GCP Self-Hosted | App Insights | Economia |
|------------|-------------------|-----------------|--------------|----------|
| 100GB | $161 | $216 | $230 | 30-43% |
| 500GB | $280 | $350 | $1,150 | 70-76% |
| 1TB | $450 | $550 | $2,300 | 75-80% |

**Nota:** Custos incluem backend, frontend, observabilidade e storage.

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-feature`
3. Commit: `git commit -m 'Adiciona nova feature'`
4. Push: `git push origin feature/nova-feature`
5. Abra um Pull Request

## 📝 Licença

Este projeto é uma POC (Proof of Concept) para fins educacionais.

## 📞 Suporte

- **Documentação**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Grafana Community**: https://community.grafana.com/
- **OpenTelemetry**: https://opentelemetry.io/docs/

---

**Desenvolvido com ❤️ usando .NET 10 + OpenTelemetry + Stack LGTM + Terraform**
