# POC Monitoring LGTM + LGPD

Prova de conceito de observabilidade com Stack LGTM (Loki + Grafana + Tempo + Mimir/Prometheus) + OpenTelemetry para aplicações .NET 10, com conformidade LGPD através de sanitização de dados sensíveis e retenção controlada.

## 📚 Documentação

- **[Visão Geral](docs/visao_geral.md)** - Comparação Stack LGTM vs Application Insights, custos, LGPD e recomendações
- **[Guia de Implantação](docs/implantacao.md)** - Instalação de ferramentas, deploy local, GCP, Azure e Kubernetes
- **[Backend API](backend/README.md)** - Documentação da API .NET 10 com OpenTelemetry e exemplos de dashboards
- **[Frontend Dashboard](frontend/monitoring-lgtm/README.md)** - Dashboard React + TypeScript + Vite para visualização
- **[Terraform Azure](terraform/azure/README.md)** - Infraestrutura como código para Azure com AKS e Managed Grafana

## 🎯 Visão Geral

### Stack LGTM
Solução open-source de observabilidade que oferece:
- **Loki**: Agregação de logs com baixo custo
- **Grafana**: Visualização unificada de métricas, logs e traces
- **Tempo**: Distributed tracing para análise de performance
- **Mimir/Prometheus**: Métricas de aplicação e infraestrutura

### Conformidade LGPD
- ✅ Sanitização automática de CPF, email, telefone, cartão, CNPJ e JWT
- ✅ Anonimização com SHA256 hash para identificação de usuários
- ✅ Retenção de 90 dias com limpeza automática
- ✅ API de exclusão para direito ao esquecimento
- ✅ Criptografia AES-256 para dados sensíveis

### Comparação de Custos (100GB/mês)
| Solução | Custo | Economia |
|---------|-------|----------|
| Stack LGTM (GCP) | $240/mês | Baseline |
| Stack LGTM (Azure) | $343/mês | -43% |
| Application Insights | $230/mês | +4% |

**Break-even**: Stack LGTM compensa a partir de 200GB/mês (economia de 25-70%)

## 🏗️ Arquitetura

### Fluxo de Dados
```
┌─────────────────┐
│   API .NET 10   │
│  + OpenTelemetry│
└────────┬────────┘
         │ OTLP
         ▼
┌─────────────────┐
│  OTel Collector │
│  + Transform    │ ◄── Sanitização LGPD
└────────┬────────┘
         │
    ┌────┴────┬────────┬──────────┐
    ▼         ▼        ▼          ▼
┌──────┐ ┌──────┐ ┌────────┐ ┌─────────┐
│ Loki │ │Tempo │ │Prometheus│ │Grafana │
│(logs)│ │(trace)│ │(metrics) │ │ (UI)   │
└──────┘ └──────┘ └────────┘ └─────────┘
```

### Camadas de Sanitização
1. **Aplicação**: `SensitiveDataLogProcessor` + `IncludeFormattedMessage=false`
2. **Collector**: Transform processor com regex patterns
3. **Storage**: Retenção de 90 dias + compactor

### Componentes
- **Backend**: API REST .NET 10 + ASP.NET Core + PostgreSQL
- **Frontend**: React + TypeScript + Vite (dashboard de monitoramento)
- **Observabilidade**: OpenTelemetry + Stack LGTM
- **Infraestrutura**: Docker Compose (local) + Kubernetes (produção)
- **IaC**: Terraform para GCP e Azure

## 🛠️ Tecnologias

### Backend
- **.NET 10** - Framework de aplicação
- **ASP.NET Core** - API REST
- **OpenTelemetry** - Instrumentação de telemetria
- **PostgreSQL** - Banco de dados relacional
- **Entity Framework Core** - ORM

### Observabilidade
- **Grafana Loki** - Agregação de logs
- **Grafana Tempo** - Distributed tracing
- **Prometheus** - Métricas de aplicação
- **Grafana** - Visualização e dashboards
- **OpenTelemetry Collector** - Pipeline de telemetria

### Frontend
- **React 18** - Framework UI
- **TypeScript** - Tipagem estática
- **Vite** - Build tool
- **Recharts** - Gráficos e visualizações

### Infraestrutura
- **Docker** - Containerização
- **Kubernetes** - Orquestração (GKE/AKS)
- **Terraform** - Infrastructure as Code
- **Helm** - Package manager para Kubernetes
- **k6** - Testes de carga

### Cloud Providers
- **Google Cloud Platform** - GKE, Cloud Storage, Cloud SQL
- **Microsoft Azure** - AKS, Blob Storage, Managed Grafana

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
    ├── azure/                        # IaC Azure
    │   ├── environments/
    │   │   ├── dev/
    │   │   ├── staging/
    │   │   └── prod/
    │   └── modules/
    │       ├── aks/
    │       ├── container-apps/
    │       ├── postgresql/
    │       └── monitoring/
    └── gcp/                          # IaC GCP
        ├── environments/
        │   ├── dev/
        │   ├── stage/
        │   └── prod/
        └── modules/
            ├── gke/
            ├── cloud-run/
            ├── cloud-sql/
            └── monitoring/
```

## 🚀 Quick Start

### 1. Pré-requisitos
```bash
# Windows 11
docker --version        # >= 24.0
dotnet --version        # >= 10.0
terraform --version     # >= 1.6
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

### 4. Deploy em Produção
```bash
# Azure (Terraform)
cd terraform/azure/environments/dev
terraform init
terraform plan
terraform apply

# Configurar kubectl
az aks get-credentials --resource-group rg-lgtm-dev --name aks-lgtm-dev

# Deploy da aplicação
kubectl apply -f ../../k8s/
```

## 📊 Dashboards Grafana

Importe os seguintes dashboards:
- **[ASP.NET Core Metrics - ID 19924](https://grafana.com/grafana/dashboards/19924)** - Visão geral de requisições
- **[ASP.NET Core Endpoint - ID 19925](https://grafana.com/grafana/dashboards/19925)** - Telemetria por endpoint

## 🔒 Conformidade LGPD

### Dados Sanitizados
- CPF: `123.456.789-10` → `***CPF-REDACTED***`
- Email: `user@email.com` → `***EMAIL-REDACTED***`
- Telefone: `(11) 98765-4321` → `***PHONE-REDACTED***`
- Cartão: `4111 1111 1111 1111` → `***CARD-REDACTED***`

### Direito ao Esquecimento
```bash
# Excluir dados de usuário
curl -X DELETE http://localhost:5000/gdpr/user/123.456.789-10
```

### Retenção
- Logs: 90 dias (Loki)
- Traces: 90 dias (Tempo)
- Métricas: 90 dias (Prometheus)
- Dados: 90 dias (PostgreSQL)

## 📈 Monitoramento

### Métricas Disponíveis
- Taxa de requisições (req/s)
- Latência (p50, p95, p99)
- Taxa de erros (4xx, 5xx)
- Uso de CPU e memória
- Conexões de banco de dados

### Logs Estruturados
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

## 💰 Estimativa de Custos

| Volume/mês | GCP LGTM | Azure LGTM | App Insights | Economia |
|------------|----------|------------|--------------|----------|
| 100GB | $240 | $343 | $230 | Baseline |
| 500GB | $450 | $620 | $1,150 | 60% |
| 1TB | $750 | $1,050 | $2,300 | 70% |

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

**Desenvolvido com ❤️ usando .NET 10 + OpenTelemetry + Stack LGTM**
