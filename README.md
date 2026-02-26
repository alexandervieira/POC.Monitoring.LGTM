# POC Monitoring LGTM + LGPD

Prova de conceito de observabilidade com Stack LGTM (Loki + Grafana + Tempo + Mimir/Prometheus) + OpenTelemetry para aplicações .NET 10, com conformidade LGPD através de sanitização de dados sensíveis e retenção controlada.

## 📚 Documentação

- **[🎯 Matriz de Decisão (Novo)](docs/decision_matrix.md)** - Guia executivo completo para escolher entre AKS, GKE, VMs e Managed Grafana com análise de custo/benefício, checklists e árvore de decisão
- **[📊 Análise de Custos (Novo)](docs/cost_analysis.md)** - Visualizações comparativas, projeções de TCO, ROI, break-even analysis e simulações por cenário
- **[🖥️ Referência VMs (Novo)](docs/vm_specs_reference.md)** - Especificações técnicas completas das VMs por ambiente com CPU, RAM, IOPS, comandos de provisioning e distribuição Docker Stack
- **[Visão Geral](docs/visao_geral.md)** - Comparação Stack LGTM vs Application Insights, custos detalhados (AKS, GKE, VMs, Managed Grafana), LGPD e decisões arquiteturais
- **[Guia de Implantação](docs/implantacao.md)** - Instalação de ferramentas, deploy local, GCP, Azure e Kubernetes
- **[🚀 Deploy em VMs (Novo)](docs/deployment_vms.md)** - Guia completo para deploy em Azure VMs e GCP Compute Engine usando Docker Compose (melhor custo/benefício para Dev/Stage)
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

### Opções de Deployment - Guia Rápido

```
┌─────────────────────────────────────────────────────────────┐
│              🎯 ESCOLHA POR AMBIENTE                         │
└─────────────────────────────────────────────────────────────┘

💰 DESENVOLVIMENTO (< 50GB/mês)
├─ Azure VM B2s: $90/mês ⭐ MELHOR CUSTO
│  ✅ CPU burst para picos ocasionais
│  ✅ Setup simples (Docker Compose)
│  ✅ 61% economia vs App Insights
│  📦 2 vCPUs, 4GB RAM, 100GB SSD
│  ⚡ Intel Xeon Platinum 8370C (2.8 GHz)
│  💾 IOPS: 2,300 (burst 5,000)
│  📚 docs/deployment_vms.md
│
└─ GCP VM Preemptible: $106/mês
   ✅ 54% economia (aceita interrupções)
   📦 2 vCPUs, 8GB RAM, 100GB SSD
   ⚠️ VM pode ser desligada pelo GCP

🧪 STAGING (50-150GB/mês)
├─ Azure VM D2s_v3: $139/mês ⭐ MELHOR CUSTO
│  ✅ Performance consistente
│  ✅ Espelho de produção
│  ✅ 54% economia vs App Insights
│  📦 2 vCPUs, 8GB RAM, 120GB Premium SSD
│  ⚡ Intel Xeon E5-2673 v4 (2.3-3.5 GHz)
│  💾 IOPS: 3,500 (consistente)
│  📚 docs/deployment_vms.md
│
└─ GCP VM n1-standard-2: $160/mês
   ✅ 47% economia
   ✅ Multi-cloud
   📦 2 vCPUs, 7.5GB RAM, 120GB SSD
   ⚡ Intel Xeon (Skylake/Broadwell)

🚀 PRODUÇÃO (> 150GB)
├─ Azure AKS: $161/mês ⭐ RECOMENDADO
│  ✅ HA nativa (99.9% SLA)
│  ✅ Auto-scaling (HPA)
│  ✅ 59% economia vs App Insights ($391)
│  ✅ 70% mais barato que VMs HA ($538)
│  📖 terraform/azure/
│
└─ GCP GKE: $216/mês
   ✅ Multi-cloud
   ✅ GKE Autopilot disponível
   📖 terraform/gcp/

📈 HIGH SCALE (> 500GB) - Única Opção Viável
├─ Azure AKS: $280-450/mês
│  ✅ 76-80% economia vs App Insights
│  ✅ VMs não escalam adequadamente
│
└─ GCP GKE: $350-550/mês
   ✅ Multi-cloud + GKE Autopilot

❌ EVITAR
├─ VMs para Produção: $538-582/mês
│  ❌ 234-269% mais caro que Kubernetes
│  ❌ Sem auto-scaling
│
└─ Azure Managed Grafana: $261/mês
   ❌ +62% custo sem reduzir complexidade
   ❌ Ainda requer gerenciar AKS completo
```

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

### Comparação de Custos por Ambiente

| Ambiente | Azure (Recomendado) | GCP | App Insights | Economia |
|----------|---------------------|-----|--------------|----------|
| **Dev** (< 50GB) | **VM B2s: $90** ⭐ | VM Preemptible: $106 | $230 | **61%** |
| **Stage** (50-150GB) | **VM D2s_v3: $139** ⭐ | VM n1-std-2: $160 | $299 | **54%** |
| **Prod** (150-200GB) | **AKS: $161** ⭐ | GKE: $216 | $391 | **59%** |
| **Prod High** (500GB) | **AKS: $280** ⭐ | GKE: $350 | $1,150 | **76%** |
| **Prod Scale** (1TB) | **AKS: $450** ⭐ | GKE: $550 | $2,300 | **80%** |

**💰 Economia Adicional com Reserved Instances (RI):**

| Modelo | Dev+Stage (3 Anos) | Economia vs PAYG | Economia vs App Insights |
|--------|---------------------|------------------|--------------------------|
| **Pay-As-You-Go** | $8,244 | Baseline | 57% |
| **Azure 3 Year RI** ⭐ | **$6,084** | **26% ↓** | **68%** |
| **Azure Stage Spot** | **$6,228** | **24% ↓** | **67%** |
| **GCP Preemptible** | **$8,316** | **22% ↓** | **58%** |
| App Insights | $19,044 | - | Baseline |

**ℹ️ Detalhes:** [docs/visao_geral.md - Seção 5.8](docs/visao_geral.md#58-reserved-instances-e-spot-vms---economia-adicional)

**Break-even**: Stack LGTM compensa a partir de 50GB/mês (economia de 47-80%)

**Recomendações por Ambiente:**
- **💰 Dev (< 50GB)**: Azure VM B2s ($90) - Melhor custo absoluto
- **🧪 Stage (50-150GB)**: Azure VM D2s_v3 ($139) - Espelho produção
- **🚀 Prod (> 150GB)**: Azure AKS ($161) - HA nativa + auto-scaling
- **📈 High Scale (> 500GB)**: AKS única opção viável (VMs não escalam)
- **💡 Economia Máxima**: Use Spot/Preemptible para Dev/Stage (até 85% desconto)

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

## 💰 Estimativa de Custos por Ambiente

### Custo Mensal por Ambiente

| Ambiente | Volume | Azure ⭐ | GCP | App Insights | Economia vs App Insights |
|----------|--------|----------|-----|--------------|-------------------------|
| **Dev** | < 50GB | **$90** (VM B2s) | $106 (VM Preempt) | $230 | **61%** ⭐⭐⭐⭐⭐ |
| **Stage** | 50-150GB | **$139** (VM D2s_v3) | $160 (VM n1-std-2) | $299 | **54%** ⭐⭐⭐⭐⭐ |
| **Prod** | 150-200GB | **$161** (AKS) | $216 (GKE) | $391 | **59%** ⭐⭐⭐⭐⭐ |
| **Prod** | 500GB | **$280** (AKS) | $350 (GKE) | $1,150 | **76%** ⭐⭐⭐⭐⭐ |
| **Prod** | 1TB | **$450** (AKS) | $550 (GKE) | $2,300 | **80%** ⭐⭐⭐⭐⭐ |

### Custo Total (Dev + Stage + Prod)

**Setup completo de 3 ambientes:**

| Componente | Solução | Custo/mês | Custo Anual |
|------------|---------|-----------|-------------|
| **Dev** (50GB) | Azure VM B2s | $90 | $1,080 |
| **Stage** (100GB) | Azure VM D2s_v3 | $139 | $1,668 |
| **Prod** (200GB) | Azure AKS | $161 | $1,932 |
| **Total LGTM** | | **$390/mês** | **$4,680/ano** |
| | | |
| **Comparação:** | | |
| Dev + Stage + Prod (App Insights) | | $920/mês | $11,040/ano |
| **Economia LGTM** | | **$530/mês** | **$6,360/ano** |
| **ROI** | | **58%** | |

### Recomendações por Cenário

**Cenário 1: Startup (orçamento limitado)**
- ✅ Dev: Azure VM B2s ($90)
- ✅ Prod: Azure AKS ($161)
- ❌ Skip Stage temporariamente
- **Total: $251/mês** (economia de 60% vs App Insights)

**Cenário 2: Empresa consolidada**
- ✅ Dev: Azure VM B2s ($90)
- ✅ Stage: Azure VM D2s_v3 ($139)
- ✅ Prod: Azure AKS ($161-280)
- **Total: $390-510/mês** (economia de 55-65%)

**Cenário 3: Enterprise (multi-cloud)**
- ✅ Dev: Azure VM B2s ($90)
- ✅ Stage: GCP VM n1-std-2 ($160)
- ✅ Prod: Azure AKS + GCP GKE ($161 + $216)
- **Total: $627/mês** (multi-cloud, economia de 40%)

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
