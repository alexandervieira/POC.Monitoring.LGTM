# Visão Geral - Stack LGTM + LGPD

## 1. Stack LGTM (Grafana) vs Application Insights

### 1.1. Stack LGTM (Loki + Grafana + Tempo + Mimir/Prometheus)

**Vantagens:**
- ✅ **Open Source**: Sem vendor lock-in
- ✅ **Custo**: Mais econômico em escala (self-hosted)
- ✅ **Flexibilidade**: Total controle sobre dados e configuração
- ✅ **Multi-cloud**: Funciona em qualquer provedor
- ✅ **LGPD**: Controle total sobre sanitização e retenção
- ✅ **Customização**: Dashboards e queries ilimitadas
- ✅ **Comunidade**: Grande ecossistema e plugins

**Desvantagens:**
- ❌ **Complexidade**: Requer gerenciamento de infraestrutura
- ❌ **Manutenção**: Atualizações e patches manuais
- ❌ **Expertise**: Curva de aprendizado maior
- ❌ **Suporte**: Depende da comunidade (ou Grafana Enterprise)

**Casos de Uso Ideais:**
- Aplicações multi-cloud
- Requisitos rigorosos de LGPD/GDPR
- Orçamento limitado em escala
- Necessidade de customização avançada

### 1.2. Application Insights (Azure)

**Vantagens:**
- ✅ **Simplicidade**: Configuração rápida e fácil
- ✅ **Integração**: Nativa com Azure e .NET
- ✅ **Gerenciado**: Sem infraestrutura para gerenciar
- ✅ **Suporte**: Suporte oficial da Microsoft
- ✅ **APM**: Application Performance Monitoring integrado
- ✅ **Alertas**: Sistema de alertas robusto

**Desvantagens:**
- ❌ **Custo**: Mais caro em escala (pay-per-GB)
- ❌ **Vendor Lock-in**: Preso ao Azure
- ❌ **LGPD**: Menos controle sobre sanitização
- ❌ **Retenção**: Limitada a 90 dias (padrão)
- ❌ **Queries**: Limitações no KQL

**Casos de Uso Ideais:**
- Aplicações 100% Azure
- Equipes pequenas sem DevOps dedicado
- Necessidade de setup rápido
- Orçamento não é limitação

---

## 2. Decisão Arquitetural: Grafana Self-Hosted (AKS/GKE)

### 2.1. ✅ Implementação: Grafana Self-Hosted

**Decisão Final:** Grafana será implantado **self-hosted no AKS (Azure) e GKE (GCP)** junto com toda a stack LGTM.

**Justificativa:**
- 💰 **Custo**: Azure Managed Grafana adiciona $100/mês sem reduzir complexidade
- 🔒 **LGPD**: Controle total sobre sanitização e retenção
- 🎯 **Consistência**: Toda stack no mesmo cluster (Loki, Tempo, Prometheus, Grafana)
- 🔧 **Flexibilidade**: Plugins ilimitados e customizações completas

### 2.2. Arquitetura Implementada (Azure)

```
┌─────────────────────────────────────────────────────────┐
│                      Azure VNet                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │                    AKS Cluster                      │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │         Namespace: monitoring                 │  │ │
│  │  │                                                │  │ │
│  │  │  ┌─────────────────────────────────────────┐ │  │ │
│  │  │  │   OpenTelemetry Collector (LGPD)        │ │  │ │
│  │  │  │   - Transform processor (sanitização)   │ │  │ │
│  │  │  │   - Attributes delete (headers)         │ │  │ │
│  │  │  └──────────┬──────────────────────────────┘ │  │ │
│  │  │             │                                 │  │ │
│  │  │    ┌────────┴────────┬──────────┬──────────┐│  │ │
│  │  │    ▼                 ▼          ▼          ▼│  │ │
│  │  │  ┌────┐          ┌─────┐    ┌────┐    ┌────┐│  │ │
│  │  │  │Loki│          │Tempo│    │Prom│    │Graf││  │ │
│  │  │  └──┬─┘          └──┬──┘    └──┬─┘    └────┘│  │ │
│  │  └─────┼───────────────┼──────────┼────────────┘  │ │
│  └────────┼───────────────┼──────────┼───────────────┘ │
│           │               │          │                  │
│  ┌────────┼───────────────┼──────────┼────────────┐    │
│  │ Container Apps         │          │            │    │
│  │  - Backend API ────────┘          │            │    │
│  └────────────────────────────────────┘            │    │
│                                                     │    │
│  ┌──────────────────────────────────────────────┐  │    │
│  │ Static Web App (Free)                        │  │    │
│  │  - Frontend React + Vite                     │  │    │
│  └──────────────────────────────────────────────┘  │    │
└─────────────────────────────────────────────────────────┘
            │               │          │
            ▼               ▼          ▼
    ┌───────────────────────────────────────────┐
    │      Azure Blob Storage (90d TTL)         │
    │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
    │  │loki-logs │ │tempo-    │ │prometheus││
    │  │          │ │traces    │ │-metrics  ││
    │  └──────────┘ └──────────┘ └──────────┘ │
    └───────────────────────────────────────────┘
```

### 2.3. Arquitetura Implementada (GCP)

```
┌─────────────────────────────────────────────────────────┐
│                      GCP VPC                             │
│  ┌────────────────────────────────────────────────────┐ │
│  │                    GKE Cluster                      │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │         Namespace: monitoring                 │  │ │
│  │  │                                                │  │ │
│  │  │  ┌─────────────────────────────────────────┐ │  │ │
│  │  │  │   OpenTelemetry Collector (LGPD)        │ │  │ │
│  │  │  │   - Transform processor (sanitização)   │ │  │ │
│  │  │  │   - Attributes delete (headers)         │ │  │ │
│  │  │  └──────────┬──────────────────────────────┘ │  │ │
│  │  │             │                                 │  │ │
│  │  │    ┌────────┴────────┬──────────┬──────────┐│  │ │
│  │  │    ▼                 ▼          ▼          ▼│  │ │
│  │  │  ┌────┐          ┌─────┐    ┌────┐    ┌────┐│  │ │
│  │  │  │Loki│          │Tempo│    │Prom│    │Graf││  │ │
│  │  │  └──┬─┘          └──┬──┘    └──┬─┘    └────┘│  │ │
│  │  └─────┼───────────────┼──────────┼────────────┘  │ │
│  └────────┼───────────────┼──────────┼───────────────┘ │
│           │               │          │                  │
│  ┌────────┼───────────────┼──────────┼────────────┐    │
│  │ Cloud Run              │          │            │    │
│  │  - Backend API ────────┘          │            │    │
│  └────────────────────────────────────┘            │    │
│                                                     │    │
│  ┌──────────────────────────────────────────────┐  │    │
│  │ Firebase Hosting                             │  │    │
│  │  - Frontend React + Vite                     │  │    │
│  └──────────────────────────────────────────────┘  │    │
└─────────────────────────────────────────────────────────┘
            │               │          │
            ▼               ▼          ▼
    ┌───────────────────────────────────────────┐
    │   Google Cloud Storage (90d lifecycle)    │
    │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
    │  │loki-logs │ │tempo-    │ │prometheus││
    │  │          │ │traces    │ │-metrics  ││
    │  └──────────┘ └──────────┘ └──────────┘ │
    └───────────────────────────────────────────┘
```

### 2.4. Comparação Completa: Opções de Deployment

#### 2.4.1. Matriz de Comparação

| Aspecto | AKS (Azure) | GKE (GCP) | Azure VMs | GCP VMs | Azure Managed Grafana |
|---------|-------------|-----------|-----------|---------|----------------------|
| **Grafana** | Self-managed | Self-managed | Self-managed | Self-managed | Managed |
| **Loki** | Self-managed | Self-managed | Self-managed | Self-managed | **Self-managed** ⚠️ |
| **Tempo** | Self-managed | Self-managed | Self-managed | Self-managed | **Self-managed** ⚠️ |
| **Prometheus** | Self-managed | Self-managed | Self-managed | Self-managed | **Self-managed** ⚠️ |
| **OTel Collector** | Self-managed | Self-managed | Self-managed | Self-managed | **Self-managed** ⚠️ |
| **Orquestração** | Kubernetes | Kubernetes | Docker Compose | Docker Compose | Kubernetes + Managed |
| **Escalabilidade** | ⭐⭐⭐⭐⭐ Auto | ⭐⭐⭐⭐⭐ Auto | ⭐⭐ Manual | ⭐⭐ Manual | ⭐⭐⭐⭐ Híbrido |
| **Alta Disponibilidade** | ⭐⭐⭐⭐⭐ Nativa | ⭐⭐⭐⭐⭐ Nativa | ⭐⭐ Manual | ⭐⭐ Manual | ⭐⭐⭐⭐ Híbrido |
| **Complexidade Setup** | Alta | Alta | Média | Média | Média-Alta |
| **Gerenciamento** | Kubectl + Helm | Kubectl + Helm | SSH + Scripts | SSH + Scripts | Portal + Kubectl |
| **Controle LGPD** | ⭐⭐⭐⭐⭐ Total | ⭐⭐⭐⭐⭐ Total | ⭐⭐⭐⭐⭐ Total | ⭐⭐⭐⭐⭐ Total | ⭐⭐⭐ Limitado |
| **Custo (100GB)** | $161/mês | $216/mês | $105/mês | $120/mês | $261/mês |
| **Custo (500GB)** | $280/mês | $350/mês | $180/mês | $210/mês | $380/mês |
| **Custo (1TB)** | $450/mês | $550/mês | $320/mês | $380/mês | $650/mês |

**⚠️ Importante:** Azure Managed Grafana **NÃO elimina** complexidade. Você ainda precisa gerenciar toda a stack LGTM (Loki, Tempo, Prometheus, OpenTelemetry Collector).

#### 2.4.2. Detalhamento por Opção

**🚀 AKS (Azure Kubernetes Service) - ✅ Recomendado para Produção**
- ✅ Escalabilidade automática (HPA)
- ✅ Alta disponibilidade nativa
- ✅ Rollback e deployment zero-downtime
- ✅ Integração com Azure Monitor (opcional)
- ✅ Controle total sobre LGPD
- ❌ Curva de aprendizado Kubernetes
- ❌ Custo base mais alto ($161/mês)

**🚀 GKE (Google Kubernetes Engine) - ✅ Recomendado para Multi-Cloud**
- ✅ Escalabilidade automática (HPA)
- ✅ Alta disponibilidade nativa
- ✅ GKE Autopilot (modo gerenciado)
- ✅ Integração com Cloud Operations (opcional)
- ✅ Controle total sobre LGPD
- ❌ Curva de aprendizado Kubernetes
- ❌ Custo 25% maior que Azure ($216/mês)

**💰 Azure VMs - ✅ Melhor Custo/Benefício (Dev/Stage)**
- ✅ Custo mais baixo ($105/mês)
- ✅ Setup mais simples (Docker Compose)
- ✅ Controle total sobre LGPD
- ✅ Ideal para ambientes não-críticos
- ❌ Escalabilidade manual
- ❌ Alta disponibilidade requer setup adicional
- ❌ Sem rollback automático

**💰 GCP Compute Engine VMs - ✅ Alternativa Econômica**
- ✅ Custo competitivo ($120/mês)
- ✅ Setup mais simples (Docker Compose)
- ✅ Controle total sobre LGPD
- ✅ Preemptible VMs para redução de custos
- ❌ Escalabilidade manual
- ❌ Alta disponibilidade requer setup adicional
- ❌ Sem rollback automático

**❌ Azure Managed Grafana - NÃO Recomendado**
- ❌ Custo 62% maior que AKS ($261/mês vs $161/mês)
- ❌ Ainda requer gerenciar AKS + stack LGTM completa
- ❌ Menos controle sobre LGPD
- ❌ Plugins limitados
- ✅ UI gerenciada com Azure AD
- ✅ SLA garantido para Grafana

#### 2.4.3. Arquitetura em VMs (Azure/GCP)

**Azure VM Setup:**
```
┌─────────────────────────────────────────────────────────┐
│                    Azure VNet                            │
│  ┌────────────────────────────────────────────────────┐ │
│  │         VM Standard_D4s_v3 (4 vCPUs, 16GB RAM)     │ │
│  │                                                     │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │         Docker Compose Stack                  │ │ │
│  │  │                                                │ │ │
│  │  │  ┌────────────────────────────────────────┐  │ │ │
│  │  │  │  OpenTelemetry Collector (LGPD)        │  │ │ │
│  │  │  └──────────┬─────────────────────────────┘  │ │ │
│  │  │             │                                 │ │ │
│  │  │    ┌────────┴────────┬──────────┬─────────┐ │ │ │
│  │  │    ▼                 ▼          ▼         ▼ │ │ │
│  │  │  ┌────┐          ┌─────┐    ┌────┐   ┌────┐│ │ │
│  │  │  │Loki│          │Tempo│    │Prom│   │Graf││ │ │
│  │  │  └────┘          └─────┘    └────┘   └────┘│ │ │
│  │  └──────────────────────────────────────────── │ │ │
│  └────────────────────────────────────────────────── │ │
│                                                       │ │
│  ┌──────────────────────────────────────────────────┐│ │
│  │ Container Instance                                ││ │
│  │  - Backend API                                    ││ │
│  └──────────────────────────────────────────────────┘│ │
└─────────────────────────────────────────────────────────┘
            │               │          │
            ▼               ▼          ▼
    ┌───────────────────────────────────────────┐
    │   Azure Blob Storage (90d lifecycle)      │
    └───────────────────────────────────────────┘
```

**Especificações VM:**
- **Azure**: Standard_D4s_v3 (4 vCPUs, 16GB RAM, 150GB SSD)
- **GCP**: n1-standard-4 (4 vCPUs, 15GB RAM, 150GB SSD)
- **OS**: Ubuntu 22.04 LTS
- **Container Runtime**: Docker 24+ com Docker Compose
- **Backup**: Azure Backup / GCP Persistent Disk Snapshots

---

## 3. LGPD: Sanitização e Anonimização (Implementado)

### 3.1. Camadas de Proteção Implementadas

**1. Aplicação (.NET 10)**
```csharp
// SensitiveDataLogProcessor
builder.Logging.AddOpenTelemetry(options => {
    options.IncludeFormattedMessage = false;  // Remove OriginalFormat
    options.ParseStateValues = false;          // Remove state parsing
    options.AddProcessor(new SensitiveDataLogProcessor());
});
```

**2. OpenTelemetry Collector (Terraform)**
```yaml
processors:
  transform/logs:
    log_statements:
      - context: log
        statements:
          - replace_pattern(body, "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "***CPF-REDACTED***")
          - replace_pattern(body, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "***EMAIL-REDACTED***")
          - replace_all_patterns(attributes, "value", "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "***CPF-REDACTED***")
  
  attributes/delete:
    actions:
      - key: http.request.header.authorization
        action: delete
```

**3. Storage (Terraform)**
```hcl
# Azure Blob Storage
lifecycle_rule {
  condition {
    age = 90
  }
  action {
    type = "Delete"
  }
}

# GCP Cloud Storage
lifecycle_rule {
  condition {
    age = 90
  }
  action {
    type = "Delete"
  }
}
```

### 3.2. Dados Sanitizados

| Tipo | Padrão | Substituição |
|------|--------|--------------|
| CPF | `123.456.789-10` | `***CPF-REDACTED***` |
| Email | `user@email.com` | `***EMAIL-REDACTED***` |
| Telefone | `(11) 98765-4321` | `***PHONE-REDACTED***` |
| Cartão | `4111 1111 1111 1111` | `***CARD-REDACTED***` |
| CNPJ | `12.345.678/0001-90` | `***CNPJ-REDACTED***` |
| JWT | `eyJhbGci...` | `***JWT-REDACTED***` |

### 3.3. Anonimização com User Hash

```csharp
// UserHashService.cs
public string GenerateUserHash(string cpf)
{
    using var sha256 = SHA256.Create();
    var bytes = Encoding.UTF8.GetBytes(cpf);
    var hash = sha256.ComputeHash(bytes);
    return Convert.ToHexString(hash).ToLower();
}

// Uso nos logs
var userHash = _userHashService.GenerateUserHash(cpf);
_logger.LogInformation("Usuário {UserId} acessou", userHash);
```

### 3.4. Conformidade LGPD

✅ **Art. 6º - Finalidade**: Logs apenas para observabilidade  
✅ **Art. 9º - Consentimento**: Usuário ciente da coleta  
✅ **Art. 15º - Acesso**: API para consultar dados  
✅ **Art. 16º - Correção**: API para atualizar dados  
✅ **Art. 18º - Exclusão**: API DELETE /gdpr/user/{cpf}  
✅ **Art. 46º - Segurança**: Criptografia AES-256 + TLS  
✅ **Art. 48º - Notificação**: Logs de acesso auditáveis  

---

## 4. Infraestrutura como Código (Terraform)

### 4.1. Módulos Implementados

**Azure:**
```
terraform/azure/
├── modules/
│   ├── network/          # VNet, Subnets, DNS
│   ├── aks/              # Kubernetes cluster
│   ├── storage/          # Blob Storage (90d lifecycle)
│   ├── postgresql/       # Flexible Server
│   ├── container-apps/   # Backend API
│   ├── static-web-app/   # Frontend React (Free tier)
│   └── monitoring/       # LGTM Stack + OTel Collector
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

**GCP:**
```
terraform/gcp/
├── modules/
│   ├── networking/       # VPC, Subnets
│   ├── gke/              # Kubernetes cluster
│   ├── cloud-storage/    # GCS buckets (90d lifecycle)
│   ├── cloud-sql/        # PostgreSQL
│   ├── cloud-run/        # Backend API
│   ├── firebase-hosting/ # Frontend React
│   └── monitoring/       # LGTM Stack + OTel Collector
└── environments/
    ├── dev/
    ├── stage/
    └── prod/
```

### 4.2. Deploy Automatizado

**Azure:**
```bash
cd terraform/azure/environments/dev
terraform init
terraform apply

# Outputs
# - otel_collector_endpoint: http://otel-collector...svc.cluster.local:4317
# - grafana_url: http://<public-ip>
# - container_app_url: https://<app>.azurecontainerapps.io
# - frontend_url: https://swa-lgtm-dev.azurestaticapps.net
```

**GCP:**
```bash
cd terraform/gcp/environments/dev
terraform init
terraform apply

# Outputs
# - otel_collector_endpoint: http://otel-collector...svc.cluster.local:4317
# - grafana_service: grafana.monitoring.svc.cluster.local
```

---

## 5. Estimativas de Custos (Atualizadas)

### 5.1. Azure AKS (Implementado) - ✅ Recomendado Produção

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| AKS | 2x Standard_D2s_v3 | $93 |
| Blob Storage | 160GB LRS + lifecycle | $18 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Container Apps | 1 app, 0.25 vCPU | $20 |
| Static Web App | Free tier | $0 |
| Load Balancer | Standard | $20 |
| **Total** | | **$161/mês** |

**Escalabilidade:**
- **500GB/mês**: +2 nodes Standard_D2s_v3 = **$280/mês**
- **1TB/mês**: +4 nodes Standard_D2s_v3 = **$450/mês**

### 5.2. GCP GKE (Implementado) - ✅ Multi-Cloud

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| GKE | 2x n1-standard-2 | $100 |
| Cloud Storage | 160GB Standard + lifecycle | $26 |
| Cloud SQL | db-n1-standard-1 | $50 |
| Cloud Run | 1 service, 0.25 vCPU | $20 |
| Firebase Hosting | Free tier | $0 |
| Load Balancer | 1 IP | $20 |
| **Total** | | **$216/mês** |

**Escalabilidade:**
- **500GB/mês**: +2 nodes n1-standard-2 = **$350/mês**
- **1TB/mês**: +4 nodes n1-standard-2 = **$550/mês**

### 5.2.1. Comparativo Técnico de VMs por Ambiente

#### Tabela de Especificações Técnicas

| Ambiente | VM | vCPUs | RAM | Storage | CPU | Network | IOPS | Custo/mês |
|----------|-----|-------|-----|---------|-----|---------|------|-----------|
| **Dev Azure** | Standard_B2s | 2 | 4 GB | 100GB SSD | Intel Xeon Platinum 8370C (2.8GHz) | 2 Gbps | 2,300 (burst 5k) | **$90** ⭐ |
| **Dev GCP** | e2-standard-2 (Preemptible) | 2 | 8 GB | 100GB SSD | Intel/AMD (shared) | 4 Gbps | 15k reads / 10k writes | **$106** |
| **Stage Azure** | Standard_D2s_v3 | 2 | 8 GB | 120GB Premium | Intel Xeon E5-2673 v4 (2.3-3.5GHz) | 5 Gbps | 3,500 | **$139** ⭐ |
| **Stage GCP** | n1-standard-2 | 2 | 7.5 GB | 120GB SSD | Intel Xeon (Skylake/Broadwell) | 10 Gbps | 25k reads / 15k writes | **$160** |

#### Distribuição de Recursos Docker Stack

**Dev (Azure B2s - 4GB RAM):**
```yaml
Grafana:                512 MB
Loki:                   1 GB
Tempo:                  512 MB
Prometheus:             1 GB
OpenTelemetry Collector: 256 MB
Sistema Operacional:    500 MB (buffer)
─────────────────────────────────
Total Alocado:          3.5 GB / 4 GB (87%)
```

**Stage (Azure D2s_v3 / GCP n1-standard-2 - ~8GB RAM):**
```yaml
Grafana:                1 GB
Loki:                   2 GB
Tempo:                  1.5 GB
Prometheus:             2 GB
OpenTelemetry Collector: 512 MB
Sistema Operacional:    1 GB (buffer + cache)
─────────────────────────────────
Total Alocado:          7 GB / 8 GB (87%)
```

#### Características por Série de VM

**Azure B-Series (Burstable):**
- ✅ CPU burst: 40% base, acumula até 100% em idle
- ✅ Ideal para cargas de trabalho intermitentes
- ✅ Melhor custo para dev (picos ocasionais)
- ⚠️ Performance inconsistente em carga contínua

**Azure D-Series (General Purpose):**
- ✅ Performance consistente 100% do tempo
- ✅ Premium SSD com IOPS previsível
- ✅ Ideal para staging (espelho prod)
- ✅ Turbo boost em workloads intensivos

**GCP E2-Series (Cost-Optimized):**
- ✅ Melhor custo/RAM (8GB por $50/mês)
- ✅ CPUs compartilhadas (Intel/AMD)
- ⚠️ Preemptible: economia 60% mas pode ser interrompida
- ⚠️ Performance varia baseado em contention

**GCP N1-Series (Balanced):**
- ✅ Performance consistente e previsível
- ✅ IOPS superiores (25k reads)
- ✅ Network até 10 Gbps
- ✅ CPUs dedicadas (sem shared)

### 5.3. Azure VM por Ambiente - 💰 Melhor Custo/Benefício

#### 5.3.1. Dev (< 50GB/mês) - Standard_B2s ⭐

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| VM | 1x Standard_B2s (2vCPU, 4GB) | $30 |
| Managed Disk | 100GB Standard SSD | $5 |
| Blob Storage | 60GB LRS + lifecycle | $8 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Container Instance | 1 app, 0.25 vCPU | $12 |
| Static Web App | Free tier | $0 |
| Public IP | Standard | $5 |
| **Total** | | **$90/mês** ⭐ |

**Configuração Técnica:**

```yaml
VM: Standard_B2s
  vCPUs: 2
  RAM: 4 GB
  Storage: 100GB Standard SSD (P10)
  CPU: Intel Xeon Platinum 8370C (2.8 GHz base)
  Network: 2 Gbps
  Max IOPS: 2,300 (burst 5,000)
  
Docker Stack:
  - Grafana: 512MB RAM
  - Loki: 1GB RAM
  - Tempo: 512MB RAM  
  - Prometheus: 1GB RAM
  - OpenTelemetry Collector: 256MB RAM
  - Total: ~3.5GB (sobra 500MB para OS)

Sistema Operacional:
  - Ubuntu 22.04 LTS
  - Docker Engine 24.0.7
  - Docker Compose 2.21.0
```

**Características:**
- ✅ Ideal para desenvolvimento local
- ✅ CPU burst (B-series) para picos ocasionais
- ✅ Downtime aceitável (1-2h/mês)
- ✅ 100% créditos CPU acumulados durante idle
- ❌ Single instance (sem HA)

#### 5.3.2. Stage (50-150GB/mês) - Standard_D2s_v3 ⭐

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| VM | 1x Standard_D2s_v3 (2vCPU, 8GB) | $70 |
| Managed Disk | 120GB Premium SSD | $10 |
| Blob Storage | 100GB LRS + lifecycle | $12 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Container Instance | 1 app, 0.25 vCPU | $12 |
| Static Web App | Free tier | $0 |
| Public IP | Standard | $5 |
| **Total** | | **$139/mês** |

**Configuração Técnica:**

```yaml
VM: Standard_D2s_v3
  vCPUs: 2
  RAM: 8 GB
  Storage: 120GB Premium SSD (P6)
  CPU: Intel Xeon E5-2673 v4 (2.3 GHz base, 3.5 GHz turbo)
  Network: Moderate (5 Gbps)
  Max IOPS: 3,500
  
Docker Stack:
  - Grafana: 1GB RAM
  - Loki: 2GB RAM
  - Tempo: 1.5GB RAM
  - Prometheus: 2GB RAM
  - OpenTelemetry Collector: 512MB RAM
  - Total: ~7GB (sobra 1GB para OS)

Sistema Operacional:
  - Ubuntu 22.04 LTS
  - Docker Engine 24.0.7
  - Docker Compose 2.21.0
  - Monitoring: Azure Monitor Agent
```

**Características:**
- ✅ Espelho de produção (mesma configuração)
- ✅ Performance consistente (D-series)
- ✅ Ideal para testes pré-produção
- ✅ Premium SSD com IOPS previsível
- ⚠️ Single instance (aceitável para stage)

#### 5.3.3. Prod (> 150GB/mês) - Use AKS ($161) ✅

**⚠️ Importante:** Para produção, **Azure AKS ($161)** é mais barato e melhor que VMs com HA.

**Comparação Produção:**

| Setup | Custo | HA | Auto-scaling |
|-------|-------|-----|--------------|
| **Azure AKS** | **$161** ✅ | ✅ Nativa | ✅ HPA |
| 2x D4s_v3 VMs + LB | $538 ❌ | ✅ Manual | ❌ Manual |

**VMs com HA (apenas referência):**
- 2x Standard_D4s_v3 (4vCPU, 16GB): $280
- 2x Managed Disk (150GB Premium): $30
- Load Balancer: $20
- PostgreSQL GP_Standard_D2s_v3: $150
- Blob Storage: $18
- Container Apps (HA): $40
- **Total: $538/mês** (234% mais caro que AKS)

### 5.4. GCP Compute Engine VM por Ambiente

#### 5.4.1. Dev (< 50GB/mês) - e2-standard-2 ⭐

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| VM | 1x e2-standard-2 (2vCPU, 8GB) | $50 |
| Persistent Disk | 100GB SSD | $15 |
| Cloud Storage | 60GB Standard + lifecycle | $10 |
| Cloud SQL | db-f1-micro | $40 |
| Cloud Run | 1 service, 0.25 vCPU | $15 |
| Firebase Hosting | Free tier | $0 |
| Static IP | 1 IP | $6 |
| **Total** | | **$136/mês** |

**💡 Economia com Preemptible:** VM = $20/mês (em vez de $50)
- **Total Preemptible: $106/mês** (-22%)
- ⚠️ VM pode ser interrompida (ok para dev não-crítico)

**Configuração Técnica:**

```yaml
VM: e2-standard-2
  vCPUs: 2
  RAM: 8 GB
  Storage: 100GB Persistent Disk SSD
  CPU: Intel/AMD (compartilhado)
  Network: Até 4 Gbps
  Max IOPS: 15,000 reads / 10,000 writes
  
Docker Stack:
  - Grafana: 512MB RAM
  - Loki: 1.5GB RAM
  - Tempo: 1GB RAM
  - Prometheus: 1.5GB RAM
  - OpenTelemetry Collector: 256MB RAM
  - Total: ~5GB (sobra 3GB para OS)

Sistema Operacional:
  - Ubuntu 22.04 LTS
  - Docker Engine 24.0.7
  - Docker Compose 2.21.0
  - Cloud Monitoring Agent
```

**Características:**
- ✅ Série E2 otimizada para custo
- ✅ Ideal para desenvolvimento
- ✅ RAM generosa (8GB) permite sobra para cache
- ⚠️ Preemptible recomendado para maior economia

#### 5.4.2. Stage (50-150GB/mês) - n1-standard-2 ⭐

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| VM | 1x n1-standard-2 (2vCPU, 7.5GB) | $50 |
| Persistent Disk | 120GB SSD | $18 |
| Cloud Storage | 100GB Standard + lifecycle | $16 |
| Cloud SQL | db-n1-standard-1 | $50 |
| Cloud Run | 1 service, 0.25 vCPU | $20 |
| Firebase Hosting | Free tier | $0 |
| Static IP | 1 IP | $6 |
| **Total** | | **$160/mês** |

**Configuração Técnica:**

```yaml
VM: n1-standard-2
  vCPUs: 2
  RAM: 7.5 GB
  Storage: 120GB Persistent Disk SSD
  CPU: Intel Xeon (Skylake, Broadwell, Haswell)
  Network: Até 10 Gbps
  Max IOPS: 25,000 reads / 15,000 writes
  
Docker Stack:
  - Grafana: 1GB RAM
  - Loki: 2GB RAM
  - Tempo: 1.5GB RAM
  - Prometheus: 2GB RAM
  - OpenTelemetry Collector: 512MB RAM
  - Total: ~7GB (sobra 500MB para OS)

Sistema Operacional:
  - Ubuntu 22.04 LTS
  - Docker Engine 24.0.7
  - Docker Compose 2.21.0
  - Cloud Monitoring Agent
  - Cloud Logging Agent
```

**Características:**
- ✅ Performance consistente (N1-series)
- ✅ Espelho de produção
- ✅ Ideal para testes pré-produção
- ✅ IOPS superiores (25k reads)
- ⚠️ Single instance (aceitável para stage)

#### 5.4.3. Prod (> 150GB/mês) - Use GKE ($216) ✅

**⚠️ Importante:** Para produção, **GCP GKE ($216)** é mais barato e melhor que VMs com HA.

**Comparação Produção:**

| Setup | Custo | HA | Auto-scaling |
|-------|-------|-----|--------------|
| **GCP GKE** | **$216** ✅ | ✅ Nativa | ✅ HPA |
| 2x n1-standard-4 VMs + LB | $582 ❌ | ✅ Manual | ❌ Manual |

**VMs com HA (apenas referência):**
- 2x n1-standard-4 (4vCPU, 15GB): $280
- 2x Persistent Disk (150GB SSD): $36
- Load Balancer + IP: $20
- Cloud SQL HA (db-n1-standard-2): $180
- Cloud Storage: $26
- Cloud Run (HA): $40
- **Total: $582/mês** (169% mais caro que GKE)

### 5.5. Azure Managed Grafana (Avaliado) - ❌ Não Recomendado

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|  
| AKS | 2x Standard_D2s_v3 (Loki, Tempo, Prom) | $93 |
| **Managed Grafana** | **Essential tier** | **$100** |
| Blob Storage | 160GB LRS + lifecycle | $18 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Container Apps | 1 app, 0.25 vCPU | $20 |
| Static Web App | Free tier | $0 |
| Load Balancer | Standard | $20 |
| **Total** | | **$261/mês** |

**⚠️ Problema:** Adiciona $100/mês mas **NÃO** elimina necessidade de gerenciar AKS, Loki, Tempo e Prometheus.

### 5.6. Application Insights (Baseline)

| Volume/mês | Ingestão | Retenção 90d | Total |
|------------|----------|--------------|-------|
| 100GB | $230 | Incluído | **$230/mês** |
| 500GB | $1,150 | Incluído | **$1,150/mês** |
| 1TB | $2,300 | Incluído | **$2,300/mês** |

**Preço:** $2.30/GB ingerido

### 5.7. Comparação Final por Ambiente

#### Cenário 1: Dev (< 50GB/mês) - Custo Mínimo

| Opção | Custo/mês | Economia vs App Insights | HA | Setup | Recomendação |
|-------|-----------|-------------------------|-----|-------|--------------|
| **Azure VM B2s** | **$90** ⭐⭐⭐⭐⭐ | **61%** | ❌ | ⭐⭐⭐⭐ Fácil | ✅ **MELHOR Dev** |
| **GCP VM Preemptible** | **$106** ⭐⭐⭐⭐ | **54%** | ❌ | ⭐⭐⭐⭐ Fácil | ✅ Dev (ok interrupção) |
| GCP VM e2-standard-2 | $136 ⭐⭐⭐ | 41% | ❌ | ⭐⭐⭐⭐ Fácil | ⚠️ Mais caro |
| Azure AKS | $161 ⭐⭐ | 30% | ✅ | ⭐⭐ Complexo | ❌ Overkill para dev |
| GCP GKE | $216 ⭐ | 6% | ✅ | ⭐⭐ Complexo | ❌ Overkill para dev |
| Application Insights | $230 | Baseline | ✅ | ⭐⭐⭐⭐⭐ Trivial | ⚠️ Vendor lock-in |

**Recomendação Dev:**
- 🥇 **Azure VM B2s ($90)** - Melhor custo/benefício
- 🥈 GCP VM Preemptible ($106) - Se aceita interrupções
- 🥉 Application Insights ($230) - Se simplicidade > custo

#### Cenário 2: Stage (50-150GB/mês) - Espelho Produção

| Opção | Custo/mês | Economia vs App Insights | HA | Setup | Recomendação |
|-------|-----------|-------------------------|-----|-------|--------------|
| **Azure VM D2s_v3** | **$139** ⭐⭐⭐⭐⭐ | **54%** | ❌ | ⭐⭐⭐⭐ Fácil | ✅ **MELHOR Stage** |
| **GCP VM n1-standard-2** | **$160** ⭐⭐⭐⭐ | **47%** | ❌ | ⭐⭐⭐⭐ Fácil | ✅ Alternativa |
| Azure AKS | $161 ⭐⭐⭐⭐ | 47% | ✅ | ⭐⭐ Complexo | ⚠️ Considere se tem K8s |
| GCP GKE | $216 ⭐⭐⭐ | 28% | ✅ | ⭐⭐ Complexo | ⚠️ Multi-cloud |
| Application Insights | $299 | Baseline | ✅ | ⭐⭐⭐⭐⭐ Trivial | ❌ Caro |

**Recomendação Stage:**
- 🥇 **Azure VM D2s_v3 ($139)** - Melhor custo, espelho prod
- 🥈 GCP VM n1-standard-2 ($160) - Multi-cloud
- 🥉 Azure AKS ($161) - Se já usa K8s em prod

#### Cenário 3: Prod (150-200GB/mês) - Alta Disponibilidade

| Opção | Custo/mês | HA | Auto-scaling | SLA | Recomendação |
|-------|-----------|-----|--------------|-----|--------------|
| **Azure AKS** | **$161** ⭐⭐⭐⭐⭐ | ✅ Nativa | ✅ HPA | 99.9% | ✅ **RECOMENDADO** |
| **GCP GKE** | **$216** ⭐⭐⭐⭐ | ✅ Nativa | ✅ HPA | 99.9% | ✅ Multi-cloud |
| Application Insights | $391 ⭐⭐⭐ | ✅ | ✅ | 99.9% | ⚠️ 59% mais caro |
| Azure VM HA | $538 ⭐ | ⚠️ Manual | ❌ | 99.5% | ❌ 234% mais caro |
| GCP VM HA | $582 | ⚠️ Manual | ❌ | 99.5% | ❌ 269% mais caro |

**Recomendação Prod:**
- 🥇 **Azure AKS ($161)** - Melhor custo + HA nativa
- 🥈 GCP GKE ($216) - Multi-cloud
- ❌ **NUNCA VMs para produção** - 234-269% mais caro que K8s

#### Cenário 4: Prod High Scale (500GB-1TB/mês)

| Opção | 500GB/mês | 1TB/mês | HA | Auto-scaling | Recomendação |
|-------|-----------|---------|-----|--------------|--------------|
| **Azure AKS** | **$280** ⭐⭐⭐⭐⭐ | **$450** ⭐⭐⭐⭐⭐ | ✅ | ✅ | ✅ **ÚNICA OPÇÃO** |
| **GCP GKE** | **$350** ⭐⭐⭐⭐ | **$550** ⭐⭐⭐⭐ | ✅ | ✅ | ✅ Multi-cloud |
| App Insights | $1,150 ❌ | $2,300 ❌ | ✅ | ✅ | ❌ 76-80% mais caro |
| Azure VM | ❌ Não escala | ❌ Não escala | ❌ | ❌ | ❌ Inviável |
| GCP VM | ❌ Não escala | ❌ Não escala | ❌ | ❌ | ❌ Inviável |

**Economia AKS vs Application Insights:**
- 500GB: $870/mês economizados (76%)
- 1TB: $1,850/mês economizados (80%)

| Opção | 1TB/mês | Economia | HA | Auto-scaling | Recomendação |
|-------|---------|----------|-----|--------------|---------------|
| **Azure AKS** | **$450** | **80%** ⭐⭐⭐⭐⭐ | ✅ Nativa | ⭐⭐⭐⭐⭐ Auto | ✅ **Única opção** |
| **GCP GKE** | **$550** | **76%** ⭐⭐⭐⭐⭐ | ✅ Nativa | ⭐⭐⭐⭐⭐ Auto | ✅ Multi-Cloud |
| Azure Managed Grafana | $650 | 72% ⭐⭐⭐⭐⭐ | ⚠️ Híbrido | ⭐⭐⭐⭐ | ⚠️ Kubernetes melhor |
| Application Insights | $2,300 | Baseline | ✅ | ✅ | ❌ Proibitivo |

### 5.8. Reserved Instances e Spot VMs - 💰 Economia Adicional

As **Instâncias Reservadas (RI)** e **Committed Use Discounts (CUD)** são "contratos de fidelidade" com descontos significativos em troca de compromisso de tempo.

#### 5.8.1. Modelos de Compra

| Modelo | Custo Relativo | Desconto | Flexibilidade | Quando Usar |
|--------|----------------|----------|---------------|-------------|
| **Pay-As-You-Go** | 100% | 0% | ✅ Total | Teste, curto prazo, workloads variáveis |
| **Reserva 1 Ano** | 60% | 40% | ⚠️ Média | Produção estável (compromisso 1 ano) |
| **Reserva 3 Anos** | 30-40% | 60-70% | ❌ Baixa | Longo prazo, workload previsível |
| **Spot/Preemptible** | 10-20% | 80-90% | ❌ Nula | Dev/Stage não-crítico (pode ser desligado) |

#### 5.8.2. Azure VM - Custos com Reserved Instances

**Dev (Standard_B2s):**

| Modelo | VM | Disco | Outros | **Total/mês** | **Total 3 Anos** | Economia |
|--------|-----|-------|--------|---------------|------------------|----------|
| **Pay-As-You-Go** | $30 | $5 | $55 | **$90** | $3,240 | Baseline |
| **1 Year RI** | $18 | $5 | $55 | **$78** | $2,808 | 13% ($432) |
| **3 Year RI** | $12 | $5 | $55 | **$72** | $2,592 | 20% ($648) |
| Spot | ❌ N/A (B-series) | $5 | $55 | N/A | N/A | N/A |

**Stage (Standard_D2s_v3):**

| Modelo | VM | Disco | Outros | **Total/mês** | **Total 3 Anos** | Economia |
|--------|-----|-------|--------|---------------|------------------|----------|
| **Pay-As-You-Go** | $70 | $10 | $59 | **$139** | $5,004 | Baseline |
| **1 Year RI** | $42 | $10 | $59 | **$111** | $3,996 | 20% ($1,008) |
| **3 Year RI** | $28 | $10 | $59 | **$97** | $3,492 | 30% ($1,512) |
| **Spot** | $14 | $10 | $59 | **$83** | $2,988 | 40% ($2,016) |

**⚠️ B-Series não suporta Spot**, mas D-Series sim.

#### 5.8.3. GCP VM - Custos com Committed Use Discounts

**Dev (e2-standard-2 Preemptible):**

| Modelo | VM | Disco | Outros | **Total/mês** | **Total 3 Anos** | Economia |
|--------|-----|-------|--------|---------------|------------------|----------|
| Pay-As-You-Go | $50 | $15 | $71 | $136 | $4,896 | Baseline |
| 1 Year CUD | $34 | $15 | $71 | $120 | $4,320 | 12% ($576) |
| 3 Year CUD | $24 | $15 | $71 | $110 | $3,960 | 19% ($936) |
| **Preemptible** ⭐ | $20 | $15 | $71 | **$106** | $3,816 | 22% ($1,080) |

**Preemptible já tem ~60% desconto** (não acumula com CUD).

**Stage (n1-standard-2):**

| Modelo | VM | Disco | Outros | **Total/mês** | **Total 3 Anos** | Economia |
|--------|-----|-------|--------|---------------|------------------|----------|
| **Pay-As-You-Go** | $50 | $18 | $92 | **$160** | $5,760 | Baseline |
| **1 Year CUD** | $34 | $18 | $92 | **$144** | $5,184 | 10% ($576) |
| **3 Year CUD** | $24 | $18 | $92 | **$134** | $4,824 | 16% ($936) |
| **Preemptible** | $15 | $18 | $92 | **$125** | $4,500 | 22% ($1,260) |

#### 5.8.4. Comparativo Final: Pay-As-You-Go vs Reserved Instances

**Cenário: Dev + Stage por 3 Anos**

| Cloud | Modelo | Dev 3Y | Stage 3Y | **Total 3Y** | Economia vs PAYG |
|-------|--------|--------|----------|--------------|------------------|
| **Azure** | **Pay-As-You-Go** | $3,240 | $5,004 | **$8,244** | Baseline |
| **Azure** | **3 Year RI** | $2,592 | $3,492 | **$6,084** | **26% ($2,160)** |
| **Azure** | **Stage Spot** | $3,240 | $2,988 | **$6,228** | **24% ($2,016)** |
| **GCP** | **Pay-As-You-Go** | $4,896 | $5,760 | **$10,656** | Baseline |
| **GCP** | **3 Year CUD** | $3,960 | $4,824 | **$8,784** | **18% ($1,872)** |
| **GCP** | **Preemptible** ⭐ | $3,816 | $4,500 | **$8,316** | **22% ($2,340)** |

**💰 Melhor Custo 3 Anos:**
1. **Azure 3 Year RI: $6,084** (mais barato, comprometimento 3 anos)
2. **Azure Stage Spot: $6,228** (segunda opção, aceita interrupções)
3. **GCP Preemptible: $8,316** (terceira opção, aceita interrupções)

#### 5.8.5. Recomendações por Cenário

**🔵 Desenvolvimento (< 1 ano):**
```
✅ Pay-As-You-Go ($90-106/mês)
- Máxima flexibilidade
- Pode desligar quando não precisar
- Sem compromisso
```

**🟢 Staging (1-3 anos estável):**
```
✅ Azure 1 Year RI ($111/mês)
- 20% economia vs Pay-As-You-Go
- Compromisso aceitável
- Performance previsível

OU

✅ Azure Spot ($83/mês)
- 40% economia vs Pay-As-You-Go
- OK para stage (aceita interrupções)
- Redeploy automático
```

**🔴 Produção Crítica:**
```
❌ NÃO use VMs (use AKS/GKE)
✅ Azure AKS 1 Year RI: ~$97/mês (40% desc vs $161)
✅ GCP GKE 1 Year CUD: ~$147/mês (32% desc vs $216)
```

#### 5.8.6. Quando Vale a Pena Reserved Instances?

| Cenário | Vale RI? | Recomendação |
|---------|----------|--------------|
| **Startup MVP (< 6 meses)** | ❌ Não | Pay-As-You-Go - Flexibilidade total |
| **Produto em validação (6-12 meses)** | ⚠️ Talvez | 1 Year RI se workload estável |
| **Produção estável (> 1 ano)** | ✅ Sim | 1 Year RI (renovar anualmente) |
| **Infraestrutura consolidada (> 3 anos)** | ✅ Sim | 3 Year RI (máxima economia) |
| **Dev/Stage com downtime OK** | ✅ Sim | **Spot/Preemptible** (80-90% desconto) |

#### 5.8.7. Risco vs Economia

```
ECONOMIA MÁXIMA                FLEXIBILIDADE MÁXIMA
    ↓                                    ↓
┌──────────┬──────────┬──────────┬──────────┐
│  Spot    │  3Y RI   │  1Y RI   │  PAYG    │
│  80-90%  │  60-70%  │  40%     │  0%      │
│  desc    │  desc    │  desc    │  desc    │
│          │          │          │          │
│  ❌ Pode  │  ❌ 3 anos│  ⚠️ 1 ano │  ✅ Total │
│  desligar│  preso   │  preso   │  livre   │
└──────────┴──────────┴──────────┴──────────┘

💡 Estratégia Recomendada:
- Dev: Spot/Preemptible (economia 80-90%)
- Stage: 1 Year RI (economia 40%, flexibilidade OK)
- Prod: AKS/GKE com 1 Year RI (economia + HA)
```

#### 5.8.8. Economia Total: PAYG vs RI vs Spot (3 Anos)

| Setup | Custo 3 Anos | vs PAYG | vs App Insights |
|-------|--------------|---------|-----------------|
| Azure Dev+Stage PAYG | $8,244 | Baseline | 58% economia |
| **Azure Dev+Stage 3Y RI** | **$6,084** ⭐ | **26% ↓** | **69% economia** |
| **Azure Stage Spot** | **$6,228** | **24% ↓** | **68% economia** |
| GCP Dev+Stage PAYG | $10,656 | Baseline | 46% economia |
| GCP Dev+Stage 3Y CUD | $8,784 | 18% ↓ | 56% economia |
| **GCP Preemptible** | **$8,316** | **22% ↓** | **58% economia** |
| App Insights Dev+Stage | $19,044 | - | Baseline |

**Conclusão:**
- **Azure 3 Year RI: $6,084** = Economia de **$12,960 vs Application Insights** (68%)
- **Melhor opção para infraestrutura estável de 3+ anos**

### 5.9. Break-Even Analysis

| Volume/mês | Stack LGTM compensa? |
|------------|---------------------|
| < 50GB | ❌ Application Insights mais simples |
| 50-100GB | ⚠️ Empate técnico (use LGPD como critério) |
| **100-500GB** | ✅ **LGTM economiza 30-84%** |
| **> 500GB** | ✅ **LGTM economiza 70-86%** |
| **Com RIs 3Y** | ✅ **LGTM economiza até 69% adicional** |

---

## 6. Recomendações Finais

### 6.1. Matriz de Decisão por Ambiente

```
┌─────────────────────────────────────────────────────────────┐
│              ESCOLHA POR AMBIENTE + VOLUME                   │
└─────────────────────────────────────────────────────────────┘

🔵 DESENVOLVIMENTO (< 50GB/mês)
├─ Orçamento mínimo? → Azure VM B2s ($90/mês) ⭐ MELHOR
├─ Multi-cloud + ok interrupção? → GCP VM Preemptible ($106/mês)
├─ Simplicidade > custo? → Application Insights ($230/mês)
└─ Já usa Kubernetes? → Use mesma infra de prod

🟢 STAGING (50-150GB/mês)
├─ Espelho produção? → Azure VM D2s_v3 ($139/mês) ⭐ MELHOR
├─ Multi-cloud? → GCP VM n1-standard-2 ($160/mês)
├─ Usa K8s em prod? → Azure AKS ($161/mês)
└─ Simplicidade total? → Application Insights ($299/mês)

🔴 PRODUÇÃO (150-200GB/mês)
├─ Azure first? → Azure AKS ($161/mês) ⭐ RECOMENDADO
├─ Multi-cloud? → GCP GKE ($216/mês)
├─ Sem DevOps? → Application Insights ($391/mês)
└─ ❌ NUNCA VMs com HA ($538-582) - Use Kubernetes

🚀 PRODUÇÃO HIGH SCALE (> 500GB/mês)
├─ Azure? → Azure AKS ($280-450/mês) ⭐ ÚNICA OPÇÃO
├─ Multi-cloud? → GCP GKE ($350-550/mês)
└─ ❌ NUNCA Application Insights ($1,150-2,300) - 76-80% mais caro
```

### 6.2. Quando Usar Cada Opção

#### ✅ Azure VM B2s ($90/mês) - 🏆 CAMPEÃO DEV
**Use quando:**
- Ambiente: **DEV apenas**
- Volume < 50GB/mês
- Orçamento muito limitado (<$100/mês)
- Downtime aceitável (1-2h/mês)
- LGPD crítico (controle total)
- Setup simples preferível

**NÃO use quando:**
- Stage ou Produção
- Precisa de performance consistente
- Volume > 50GB/mês

#### ✅ Azure VM D2s_v3 ($139/mês) - 🏆 CAMPEÃO STAGE
**Use quando:**
- Ambiente: **STAGE apenas**
- Volume 50-150GB/mês
- Espelho de produção desejado
- Orçamento < $150/mês
- Downtime aceitável (testes)
- LGPD crítico (controle total)

**NÃO use quando:**
- Produção (use AKS $161)
- Volume > 150GB/mês
- HA obrigatória
├─ Multi-cloud? → GCP GKE ($550/mês)
└─ ❌ NUNCA Application Insights ($1,150+/mês)
```

### 6.2. Quando Usar Cada Opção

#### ✅ Azure VM ($105/mês)
**Use quando:**
- Volume < 200GB/mês
- Ambiente dev/stage não-crítico
- Orçamento muito limitado
- Setup simples preferível
- Equipe pequena sem expertise Kubernetes
- LGPD crítico (controle total)

**NÃO use quando:**
- Produção com SLA rigoroso
- Volume > 200GB/mês
- Necessidade de auto-scaling
- Alta disponibilidade obrigatória

#### ✅ Azure AKS ($161/mês) - 🏆 CAMPEÃO PRODUÇÃO
**Use quando:**
- Ambiente: **PRODUÇÃO**
- Volume > 100GB/mês
- SLA > 99% obrigatório
- Auto-scaling necessário
- Alta disponibilidade obrigatória
- Equipe com expertise Kubernetes
- LGPD crítico (controle total)
- Deploy zero-downtime necessário

**NÃO use quando:**
- Dev/Stage (use VMs mais baratas)
- Equipe SEM expertise Kubernetes
- Volume < 100GB/mês

#### ✅ GCP GKE ($216/mês) - 🏆 MULTI-CLOUD
**Use quando:**
- Ambiente: **PRODUÇÃO**
- Volume > 100GB/mês
- Multi-cloud estratégico
- GKE Autopilot preferível
- Produção com SLA
- LGPD crítico (controle total)

**NÃO use quando:**
- 100% Azure (use AKS, 25% mais barato)
- Dev/Stage (use VMs mais baratas)

#### ⚠️ Application Insights
**Use quando:**
- Volume < 50GB/mês
- 100% Azure sem planos de mudança
- Equipe pequena SEM DevOps
- Setup rápido prioritário
- Orçamento não é limitação

**NÃO use quando:**
- Volume > 100GB/mês (muito caro)
- Requisitos rigorosos de LGPD
- Multi-cloud planejado
- Orçamento limitado

#### ❌ Azure Managed Grafana ($261/mês) - NÃO RECOMENDADO
**Use APENAS quando:**
- Já usa Azure Monitor extensivamente
- Necessidade de Azure AD integrado
- Orçamento não é limitação
- Aceita gerenciar AKS + Loki + Tempo + Prometheus

**NÃO use (maioria dos casos):**
- ❌ Adiciona $100/mês sem reduzir complexidade
- ❌ Ainda precisa gerenciar toda stack LGTM no AKS
- ❌ Menos controle sobre LGPD
- ❌ Plugins limitados
- ✅ Use AKS self-hosted ($161/mês) em vez disso

### 6.3. Comparação Rápida

| Critério | Azure VM | GCP VM | Azure AKS | GCP GKE | App Insights | Managed Grafana |
|----------|----------|--------|-----------|---------|--------------|-----------------|
| **Custo (100GB)** | ⭐⭐⭐⭐⭐ $105 | ⭐⭐⭐⭐ $120 | ⭐⭐⭐ $161 | ⭐⭐ $216 | ⭐⭐ $230 | ⭐ $261 |
| **Produção** | ❌ | ❌ | ✅ | ✅ | ✅ | ⚠️ |
| **Auto-scaling** | ❌ | ❌ | ✅ | ✅ | ✅ | ⚠️ |
| **LGPD Total** | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| **Setup** | ⭐⭐⭐⭐ Fácil | ⭐⭐⭐⭐ Fácil | ⭐⭐ Complexo | ⭐⭐ Complexo | ⭐⭐⭐⭐⭐ Trivial | ⭐⭐⭐ Médio |
| **Manutenção** | ⭐⭐ Manual | ⭐⭐ Manual | ⭐⭐⭐ Kubectl | ⭐⭐⭐ Kubectl | ⭐⭐⭐⭐⭐ Zero | ⭐⭐⭐⭐ Baixo |
| **Multi-cloud** | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ |

---

## 7. Próximos Passos

1. ✅ **Terraform**: Infraestrutura provisionada (Azure + GCP)
2. ✅ **LGPD**: Sanitização implementada (4 camadas)
3. ✅ **Retenção**: 90 dias configurado (storage lifecycle)
4. ✅ **Frontend**: Azure Static Web App / Firebase Hosting
5. 🔄 **CI/CD**: Configurar pipelines de deploy
6. 🔄 **Dashboards**: Importar templates Grafana (19924, 19925)
7. 🔄 **Alertas**: Configurar Prometheus AlertManager
8. 🔄 **Testes**: Validar sanitização em produção
