# Referência Rápida: Especificações Técnicas das VMs

## 📋 Resumo Executivo

Este documento contém as especificações técnicas completas das VMs recomendadas para cada ambiente.

---

## 1. Desenvolvimento (< 50GB/mês)

### 1.1. Azure Standard_B2s - $90/mês ⭐ RECOMENDADO

#### Especificações Gerais
| Item | Valor |
|------|-------|
| **vCPUs** | 2 |
| **RAM** | 4 GB |
| **Storage** | 100GB Standard SSD (P10) |
| **CPU** | Intel Xeon Platinum 8370C @ 2.8 GHz base |
| **Network** | 2 Gbps |
| **IOPS** | 2,300 normal / 5,000 burst |
| **Burst Credits** | 40% base + acumula até 100% em idle |

#### Docker Stack (3.5GB alocados)
```yaml
Grafana:                 512 MB
Loki:                    1 GB
Tempo:                   512 MB
Prometheus:              1 GB
OpenTelemetry Collector: 256 MB
Sistema Operacional:     500 MB (buffer)
───────────────────────────────
Total:                   3.5 GB / 4 GB (87%)
```

#### Sistema Operacional
- Ubuntu 22.04 LTS
- Docker Engine 24.0.7
- Docker Compose 2.21.0

#### Características
- ✅ Ideal para desenvolvimento local
- ✅ CPU burst para picos de 2-3 horas
- ✅ Downtime aceitável (1-2h/mês)
- ✅ 100% créditos CPU em períodos idle
- ❌ Single instance (sem HA)

#### Comando Provisioning
```bash
az vm create \
  --resource-group rg-lgtm-vm-dev \
  --name vm-lgtm-dev \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --os-disk-size-gb 100 \
  --storage-sku StandardSSD_LRS
```

---

### 1.2. GCP e2-standard-2 Preemptible - $106/mês

#### Especificações Gerais
| Item | Valor |
|------|-------|
| **vCPUs** | 2 |
| **RAM** | 8 GB |
| **Storage** | 100GB Persistent Disk SSD |
| **CPU** | Intel/AMD (compartilhado) |
| **Network** | Até 4 Gbps |
| **IOPS** | 15,000 reads / 10,000 writes |
| **Availability** | 99.0% (pode ser interrompida) |

#### Docker Stack (5GB alocados)
```yaml
Grafana:                 512 MB
Loki:                    1.5 GB
Tempo:                   1 GB
Prometheus:              1.5 GB
OpenTelemetry Collector: 256 MB
Sistema Operacional:     3 GB (buffer generoso)
───────────────────────────────
Total:                   5 GB / 8 GB (62%)
```

#### Sistema Operacional
- Ubuntu 22.04 LTS
- Docker Engine 24.0.7
- Docker Compose 2.21.0
- Cloud Monitoring Agent

#### Características
- ✅ Série E2 otimizada para custo
- ✅ RAM generosa (8GB) permite cache
- ✅ IOPS superiores ao Azure B2s
- ⚠️ Preemptible: VM pode ser interrompida (economia 60%)
- ⚠️ Performance varia (CPU compartilhada)

#### Comando Provisioning
```bash
gcloud compute instances create lgtm-dev \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --preemptible \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-standard \
  --tags=lgtm-dev
```

---

## 2. Staging (50-150GB/mês)

### 2.1. Azure Standard_D2s_v3 - $139/mês ⭐ RECOMENDADO

#### Especificações Gerais
| Item | Valor |
|------|-------|
| **vCPUs** | 2 |
| **RAM** | 8 GB |
| **Storage** | 120GB Premium SSD (P6) |
| **CPU** | Intel Xeon E5-2673 v4 @ 2.3 GHz base / 3.5 GHz turbo |
| **Network** | Moderate (5 Gbps) |
| **IOPS** | 3,500 (consistente) |
| **Performance** | 100% sempre (sem burst) |

#### Docker Stack (7GB alocados)
```yaml
Grafana:                 1 GB
Loki:                    2 GB
Tempo:                   1.5 GB
Prometheus:              2 GB
OpenTelemetry Collector: 512 MB
Sistema Operacional:     1 GB (buffer + cache)
───────────────────────────────
Total:                   7 GB / 8 GB (87%)
```

#### Sistema Operacional
- Ubuntu 22.04 LTS
- Docker Engine 24.0.7
- Docker Compose 2.21.0
- Azure Monitor Agent

#### Características
- ✅ Espelho de produção (mesma configuração)
- ✅ Performance consistente (D-series)
- ✅ Premium SSD com IOPS previsível
- ✅ Turbo boost em workloads intensivos
- ✅ Ideal para testes pré-produção
- ⚠️ Single instance (aceitável para stage)

#### Comando Provisioning
```bash
az vm create \
  --resource-group rg-lgtm-vm-stage \
  --name vm-lgtm-stage \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --os-disk-size-gb 120 \
  --storage-sku Premium_LRS
```

---

### 2.2. GCP n1-standard-2 - $160/mês

#### Especificações Gerais
| Item | Valor |
|------|-------|
| **vCPUs** | 2 |
| **RAM** | 7.5 GB |
| **Storage** | 120GB Persistent Disk SSD |
| **CPU** | Intel Xeon (Skylake, Broadwell, Haswell) |
| **Network** | Até 10 Gbps |
| **IOPS** | 25,000 reads / 15,000 writes |
| **Availability** | 99.5% |

#### Docker Stack (7GB alocados)
```yaml
Grafana:                 1 GB
Loki:                    2 GB
Tempo:                   1.5 GB
Prometheus:              2 GB
OpenTelemetry Collector: 512 MB
Sistema Operacional:     500 MB (buffer)
───────────────────────────────
Total:                   7 GB / 7.5 GB (93%)
```

#### Sistema Operacional
- Ubuntu 22.04 LTS
- Docker Engine 24.0.7
- Docker Compose 2.21.0
- Cloud Monitoring Agent
- Cloud Logging Agent

#### Características
- ✅ Performance consistente (N1-series)
- ✅ IOPS superiores (25k reads)
- ✅ Network até 10 Gbps (2x mais que Azure)
- ✅ CPUs dedicadas (sem shared)
- ✅ Espelho de produção
- ✅ Ideal para multi-cloud
- ⚠️ Single instance (aceitável para stage)

#### Comando Provisioning
```bash
gcloud compute instances create lgtm-stage \
  --zone=us-central1-a \
  --machine-type=n1-standard-2 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=120GB \
  --boot-disk-type=pd-ssd \
  --tags=lgtm-stage
```

---

## 3. Comparativo Completo

### 3.1. Tabela de Comparação

| Métrica | Azure B2s (Dev) | GCP e2-std-2 (Dev) | Azure D2s_v3 (Stage) | GCP n1-std-2 (Stage) |
|---------|-----------------|-------------------|----------------------|---------------------|
| **Custo** | **$90** ⭐ | $106 | **$139** ⭐ | $160 |
| **vCPUs** | 2 | 2 | 2 | 2 |
| **RAM** | 4 GB | 8 GB | 8 GB | 7.5 GB |
| **Storage** | 100GB SSD | 100GB SSD | 120GB Premium | 120GB SSD |
| **IOPS Reads** | 2,300 (5k burst) | 15,000 | 3,500 | 25,000 |
| **IOPS Writes** | 2,300 (5k burst) | 10,000 | 3,500 | 15,000 |
| **Network** | 2 Gbps | 4 Gbps | 5 Gbps | 10 Gbps |
| **CPU Type** | Xeon Platinum 8370C | Intel/AMD shared | Xeon E5-2673 v4 | Xeon Skylake+ |
| **Burst CPU** | ✅ Sim (40% base) | ❌ Não | ❌ Não | ❌ Não |
| **Preemptible** | ❌ Não | ✅ Sim (opcional) | ❌ Não | ❌ Não |

### 3.2. Economia vs Application Insights

| Ambiente | VM Escolhida | Custo VM | App Insights | Economia |
|----------|--------------|----------|--------------|----------|
| Dev (50GB) | Azure B2s | **$90** | $230 | **61%** |
| Dev (50GB) | GCP e2-std-2 | **$106** | $230 | **54%** |
| Stage (100GB) | Azure D2s_v3 | **$139** | $299 | **54%** |
| Stage (100GB) | GCP n1-std-2 | **$160** | $299 | **47%** |
| **Total 2 envs** | **Azure** | **$229** | **$529** | **57%** |
| **Total 2 envs** | **GCP** | **$266** | **$529** | **50%** |

### 3.3. Reserved Instances e Spot VMs - Economia Adicional

**Reserved Instances (RI)** e **Committed Use Discounts (CUD)** oferecem descontos significativos em troca de compromisso de tempo:

#### Modelos de Compra

| Modelo | Custo | Desconto | Flexibilidade | Quando Usar |
|--------|-------|----------|---------------|-------------|
| **Pay-As-You-Go** | 100% | 0% | ✅ Total | Teste, MVP, workloads variáveis |
| **Reserva 1 Ano** | ~60% | 40% | ⚠️ Média | Produção estável (1 ano) |
| **Reserva 3 Anos** | ~30-40% | 60-70% | ❌ Baixa | Infraestrutura consolidada |
| **Spot/Preemptible** | ~10-20% | 80-90% | ❌ Nula | Dev/Stage (aceita interrupções) |

#### Custos com Reserved Instances (3 Anos)

**Azure:**

| Ambiente | VM | Pay-As-You-Go | 1Y RI | 3Y RI | Spot | Melhor Opção |
|----------|-----|---------------|-------|-------|------|--------------|
| **Dev** | B2s | **$90** | $78 | $72 | ❌ N/A | Pay-As-You-Go ou 3Y RI |
| **Stage** | D2s_v3 | **$139** | $111 | $97 | **$83** | **Spot ($83)** ⭐ |

**GCP:**

| Ambiente | VM | Pay-As-You-Go | 1Y CUD | 3Y CUD | Preemptible | Melhor Opção |
|----------|-----|---------------|--------|--------|-------------|--------------|
| **Dev** | e2-std-2 | $136 | $120 | $110 | **$106** | **Preemptible** ⭐ |
| **Stage** | n1-std-2 | **$160** | $144 | $134 | **$125** | **Preemptible ($125)** ⭐ |

#### Economia Total (Dev + Stage por 3 Anos)

| Cloud | Modelo | Custo 3 Anos | vs PAYG | vs App Insights |
|-------|--------|--------------|---------|-----------------|
| Azure | Pay-As-You-Go | $8,244 | Baseline | 57% ↓ |
| **Azure** | **3 Year RI** | **$6,084** | **26% ↓** | **68% ↓** ⭐ |
| **Azure** | **Stage Spot** | **$6,228** | **24% ↓** | **67% ↓** |
| GCP | Pay-As-You-Go | $10,656 | Baseline | 46% ↓ |
| GCP | 3 Year CUD | $8,784 | 18% ↓ | 56% ↓ |
| **GCP** | **Preemptible** | **$8,316** | **22% ↓** | **58% ↓** |
| - | App Insights | $19,044 | - | Baseline |

**💰 Melhor Custo 3 Anos: Azure 3 Year RI = $6,084 (economia de $12,960 vs App Insights)**

---

## 4. Características por Série de VM

### 4.1. Azure B-Series (Burstable)
**Ideal para:** Desenvolvimento, cargas intermitentes

**Prós:**
- ✅ Menor custo ($30/mês base VM)
- ✅ CPU burst para picos (até 100%)
- ✅ Créditos acumulam em idle
- ✅ Ideal para dev (uso 20-40% do tempo)

**Contras:**
- ❌ Performance inconsistente em carga contínua
- ❌ Se esgotar créditos, CPU limita a 40%
- ❌ Não recomendado para staging/prod

### 4.2. Azure D-Series (General Purpose)
**Ideal para:** Staging, produção

**Prós:**
- ✅ Performance 100% consistente
- ✅ Premium SSD padrão
- ✅ Turbo boost automático
- ✅ Ideal para espelho de produção

**Contras:**
- ❌ Custo 2.3x maior que B-series ($70 vs $30)
- ❌ Overkill para desenvolvimento básico

### 4.3. GCP E2-Series (Cost-Optimized)
**Ideal para:** Desenvolvimento, workloads não-críticos

**Prós:**
- ✅ Melhor custo/RAM (8GB por $50)
- ✅ IOPS elevados para leitura
- ✅ Preemptible: -60% custo (ok para dev)

**Contras:**
- ❌ CPU compartilhada (performance varia)
- ❌ Preemptible pode ser interrompida
- ❌ Não recomendado para cargas críticas

### 4.4. GCP N1-Series (Balanced)
**Ideal para:** Staging, produção, multi-cloud

**Prós:**
- ✅ Performance consistente
- ✅ IOPS superiores (25k reads)
- ✅ Network até 10 Gbps
- ✅ CPUs dedicadas

**Contras:**
- ❌ Custo 15% maior que Azure D2s_v3
- ❌ RAM ligeiramente menor (7.5GB vs 8GB)

---

## 5. Recomendações Finais

### 5.1. Escolha por Cenário

**Custo Mínimo (Dev):**
```
Azure Standard_B2s: $90/mês
✅ Melhor custo absoluto
✅ Suficiente para dev local
⚠️ Aceita downtime ocasional
```

**Performance Consistente (Stage):**
```
Azure Standard_D2s_v3: $139/mês
✅ Espelho de produção
✅ IOPS previsível
✅ Premium SSD
```

**Multi-Cloud (Dev+Stage):**
```
GCP e2-standard-2 (Dev): $106/mês
GCP n1-standard-2 (Stage): $160/mês
Total: $266/mês
✅ Diversificação de provedores
✅ IOPS superiores
```

**Alta Disponibilidade (Prod):**
```
❌ NÃO use VMs
✅ Azure AKS: $161/mês
✅ GCP GKE: $216/mês

VMs com HA custam $538-582 (234-269% mais caro)
```

### 5.2. Quando NÃO Usar VMs

❌ **Produção com SLA > 99%**
- Use Kubernetes (AKS/GKE)
- VMs requerem HA manual ($538+)

❌ **Volume > 200GB/mês**
- Scaling manual não escala
- K8s HPA automático é essencial

❌ **Auto-scaling obrigatório**
- VMs escalam manualmente
- K8s HPA responde em segundos

---

## 6. Links Úteis

- 📖 [Guia Completo de Deploy VMs](./deployment_vms.md)
- 📊 [Análise de Custos Detalhada](./cost_analysis.md)
- 🎯 [Matriz de Decisão](./decision_matrix.md)
- 📄 [Visão Geral Completa](./visao_geral.md)
- 🏠 [README Principal](../README.md)

---

**Última Atualização:** 25 de Fevereiro de 2026
