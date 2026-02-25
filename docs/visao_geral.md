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
└───────────┼───────────────┼──────────┼─────────────────┘
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
└───────────┼───────────────┼──────────┼─────────────────┘
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

### 2.4. Comparação: Self-Hosted vs Managed Grafana

| Aspecto | Self-Hosted (AKS/GKE) | Azure Managed Grafana |
|---------|----------------------|----------------------|
| **Grafana** | Self-managed | Managed |
| **Loki** | Self-managed (AKS) | **Self-managed (AKS)** ⚠️ |
| **Tempo** | Self-managed (AKS) | **Self-managed (AKS)** ⚠️ |
| **Prometheus** | Self-managed (AKS) | **Self-managed (AKS)** ⚠️ |
| **OTel Collector** | Self-managed (AKS) | **Self-managed (AKS)** ⚠️ |
| **Custo (100GB)** | $161/mês (Azure) | $261/mês (Azure) |
| **Custo (100GB)** | $240/mês (GCP) | N/A |
| **Complexidade** | Alta | Média-Alta |
| **Controle LGPD** | Total | Limitado |
| **Plugins** | Ilimitados | Limitados |

**⚠️ Importante:** Azure Managed Grafana **NÃO elimina** AKS. Você ainda precisa gerenciar Loki, Tempo, Prometheus e OpenTelemetry Collector no AKS.

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

### 5.1. Azure Self-Hosted (Implementado)

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| AKS | 2x Standard_D2s_v3 | $93 |
| Blob Storage | 160GB LRS + lifecycle | $18 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Container Apps | 1 app, 0.25 vCPU | $20 |
| Load Balancer | Standard | $20 |
| **Total** | | **$161/mês** |

### 5.2. GCP Self-Hosted (Implementado)

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| GKE | 2x n1-standard-2 | $100 |
| Cloud Storage | 160GB Standard + lifecycle | $26 |
| Cloud SQL | db-n1-standard-1 | $50 |
| Cloud Run | 1 service, 0.25 vCPU | $20 |
| Load Balancer | 1 IP | $20 |
| **Total** | | **$216/mês** |

### 5.3. Comparação Final

| Volume/mês | Azure Self-Hosted | GCP Self-Hosted | App Insights | Economia |
|------------|-------------------|-----------------|--------------|----------|
| 100GB | $161 | $216 | $230 | 30-43% |
| 500GB | $280 | $350 | $1,150 | 70-76% |
| 1TB | $450 | $550 | $2,300 | 75-80% |

---

## 6. Recomendações Finais

### 6.1. Quando Usar Stack LGTM Self-Hosted

✅ Volume > 100GB/mês  
✅ Requisitos rigorosos de LGPD  
✅ Multi-cloud ou migração futura  
✅ Equipe DevOps experiente  
✅ Necessidade de customização  
✅ Orçamento limitado em escala  

### 6.2. Quando Usar Application Insights

✅ Volume < 50GB/mês  
✅ 100% Azure sem planos de mudança  
✅ Equipe pequena sem DevOps  
✅ Necessidade de setup rápido  
✅ Orçamento não é limitação  

### 6.3. ❌ NÃO Usar Azure Managed Grafana

❌ Adiciona $100/mês sem reduzir complexidade  
❌ Ainda precisa gerenciar AKS + Loki + Tempo + Prometheus  
❌ Menos controle sobre LGPD  
❌ Plugins limitados  

**Exceção:** Apenas se já usa Azure Monitor extensivamente e precisa de visualização unificada com Azure AD.

---

## 7. Próximos Passos

1. ✅ **Terraform**: Infraestrutura provisionada (Azure + GCP)
2. ✅ **LGPD**: Sanitização implementada (4 camadas)
3. ✅ **Retenção**: 90 dias configurado (storage lifecycle)
4. 🔄 **CI/CD**: Configurar pipelines de deploy
5. 🔄 **Dashboards**: Importar templates Grafana (19924, 19925)
6. 🔄 **Alertas**: Configurar Prometheus AlertManager
7. 🔄 **Testes**: Validar sanitização em produção
