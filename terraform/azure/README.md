# Terraform Azure - Stack LGTM + LGPD

## Decisão Arquitetural: Onde Implantar o Grafana?

### ✅ Decisão Final: Grafana Self-Hosted no AKS

**Justificativa:**

1. **Custo-Benefício**: Azure Managed Grafana adiciona $100/mês sem reduzir significativamente a complexidade
2. **Controle LGPD**: Maior controle sobre dados e configurações de sanitização
3. **Flexibilidade**: Plugins ilimitados e customizações completas
4. **Consistência**: Toda stack LGTM no mesmo cluster AKS

### Arquitetura Implementada

```
┌─────────────────────────────────────────────────────────────┐
│                         Azure AKS                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Namespace: monitoring                      │ │
│  │                                                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌───────┐│ │
│  │  │   Loki   │  │  Tempo   │  │ Prometheus │  │Grafana││ │
│  │  │  (logs)  │  │ (traces) │  │ (metrics)  │  │ (UI)  ││ │
│  │  └────┬─────┘  └────┬─────┘  └─────┬──────┘  └───┬───┘│ │
│  │       │             │               │              │    │ │
│  └───────┼─────────────┼───────────────┼──────────────┼────┘ │
│          │             │               │              │      │
└──────────┼─────────────┼───────────────┼──────────────┼──────┘
           │             │               │              │
           ▼             ▼               ▼              ▼
    ┌──────────────────────────────────────────────────────┐
    │           Azure Blob Storage (stlgtmdev)             │
    │  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐ │
    │  │ loki-logs   │ │tempo-traces  │ │prometheus-   │ │
    │  │ (90d TTL)   │ │ (90d TTL)    │ │metrics       │ │
    │  └─────────────┘ └──────────────┘ └──────────────┘ │
    └──────────────────────────────────────────────────────┘
```

### Comparação: Self-Hosted vs Managed Grafana

| Aspecto | Self-Hosted (AKS) | Azure Managed Grafana |
|---------|-------------------|----------------------|
| **Custo** | Incluído no AKS | +$100/mês |
| **Loki/Tempo/Prometheus** | AKS (obrigatório) | AKS (obrigatório) ⚠️ |
| **Grafana** | AKS | Managed |
| **Complexidade** | Alta | Média-Alta |
| **Controle LGPD** | Total | Limitado |
| **Plugins** | Ilimitados | Limitados |
| **Customização** | Total | Limitada |

**⚠️ Importante**: Azure Managed Grafana **NÃO elimina** a necessidade de AKS. Você ainda precisa provisionar e gerenciar Loki, Tempo e Prometheus no AKS.

## Estrutura de Módulos

```
terraform/azure/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── modules/
    ├── aks/              # Cluster Kubernetes
    ├── storage/          # Blob Storage para LGTM
    ├── monitoring/       # Helm charts (Loki, Tempo, Prometheus, Grafana)
    ├── container-apps/   # Backend API
    └── postgresql/       # Banco de dados
```

## Storage Account (LGPD Compliance)

### Containers Criados

- **loki-logs**: Logs com retenção de 90 dias
- **tempo-traces**: Traces com retenção de 90 dias
- **prometheus-metrics**: Métricas com retenção de 90 dias

### Lifecycle Management

Todos os containers têm políticas de lifecycle que deletam automaticamente dados após 90 dias (conformidade LGPD).

## Deploy

### 1. Pré-requisitos

```bash
# Azure CLI
az login

# Terraform
terraform version  # >= 1.6

# Helm
helm version  # >= 3.12

# kubectl
kubectl version  # >= 1.28
```

### 2. Inicializar Terraform

```bash
cd terraform/azure/environments/dev
terraform init
```

### 3. Planejar

```bash
terraform plan -out=tfplan
```

### 4. Aplicar

```bash
terraform apply tfplan
```

### 5. Obter Credenciais do AKS

```bash
az aks get-credentials \
  --resource-group rg-lgtm-dev \
  --name aks-lgtm-dev
```

### 6. Verificar Pods

```bash
kubectl get pods -n monitoring
```

### 7. Acessar Grafana

```bash
# Obter IP público
terraform output grafana_url

# Credenciais padrão
# User: admin
# Password: admin (alterar no primeiro login)
```

## Custos Estimados (Dev)

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| AKS | 2x Standard_D2s_v3 | $93 |
| Storage Account | LRS, 160GB | $18 |
| PostgreSQL | B_Standard_B1ms | $30 |
| Load Balancer | Standard | $20 |
| **Total** | | **~$161/mês** |

## Próximos Passos

1. Configurar CI/CD para deploy automático
2. Configurar alertas no Prometheus
3. Importar dashboards do Grafana (IDs 19924, 19925)
4. Configurar backup do Grafana (dashboards, datasources)
5. Implementar autenticação Azure AD no Grafana

## Alternativa: GCP (GKE)

Para GCP, a mesma decisão se aplica: **Grafana self-hosted no GKE** para melhor custo-benefício e controle LGPD.

Veja: `terraform/gcp/`
