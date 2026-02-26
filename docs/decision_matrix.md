# Matriz de Decisão - Stack LGTM para Observabilidade

## Resumo Executivo

Este documento fornece uma análise comparativa completa de todas as opções de deployment para Stack LGTM (Loki, Grafana, Tempo, Prometheus) + OpenTelemetry, incluindo estimativas de custo, complexidade e recomendações por cenário.

---

## 1. Comparação Rápida - Todas as Opções

| Opção | Custo (100GB) | Custo (500GB) | Custo (1TB) | Produção | Auto-Scale | LGPD Total | Setup |
|-------|---------------|---------------|-------------|----------|------------|------------|-------|
| **Azure VM** | **$105** ⭐ | $180 | ❌ | ❌ | ❌ | ✅ | ⭐⭐⭐⭐ Fácil |
| **GCP VM** | $120 | $210 | ❌ | ❌ | ❌ | ✅ | ⭐⭐⭐⭐ Fácil |
| **Azure AKS** | **$161** ✅ | **$280** ✅ | **$450** ✅ | ✅ | ✅ | ✅ | ⭐⭐ Complexo |
| **GCP GKE** | $216 | $350 | $550 | ✅ | ✅ | ✅ | ⭐⭐ Complexo |
| App Insights | $230 | $1,150 | $2,300 | ✅ | ✅ | ⚠️ | ⭐⭐⭐⭐⭐ Trivial |
| Managed Grafana | $261 | $380 | $650 | ⚠️ | ⚠️ | ⚠️ | ⭐⭐⭐ Médio |

**Legenda:**
- ⭐ = Melhor custo/benefício
- ✅ = Recomendado / Suportado
- ⚠️ = Com ressalvas
- ❌ = Não recomendado / Não suporta

---

## 2. Análise por Cenário

### 2.1. Cenário: Dev/Stage (< 200GB/mês)

**Recomendação: Azure VM - $105/mês** ⭐

| Critério | Azure VM | GCP VM | Azure AKS | Justificativa |
|----------|----------|--------|-----------|---------------|
| **Custo** | $105 ⭐⭐⭐⭐⭐ | $120 ⭐⭐⭐⭐ | $161 ⭐⭐⭐ | VM 35% mais barata que AKS |
| **Setup** | Docker Compose | Docker Compose | Kubernetes | VM setup em < 1h |
| **Manutenção** | SSH + scripts | SSH + scripts | kubectl + Helm | VM mais simples |
| **HA Necessária?** | ❌ | ❌ | ✅ | Dev/Stage tolera downtime |
| **LGPD** | ✅ Total | ✅ Total | ✅ Total | Todas atendem |
| **Escalabilidade** | Manual | Manual | Auto | Dev/Stage não precisa auto-scale |

**Decisão:**
```
✅ USE Azure VM se:
   - Orçamento < $120/mês
   - Equipe sem expertise Kubernetes
   - Downtime aceitável
   - Volume < 200GB/mês

⚠️ CONSIDERE GCP VM se:
   - Multi-cloud desejado
   - Preemptible aceitável ($72/mês)
```

**Documentação:** [docs/deployment_vms.md](deployment_vms.md)

---

### 2.2. Cenário: Produção Pequena (100-200GB/mês)

**Recomendação: Azure AKS - $161/mês** ✅

| Critério | Azure VM | Azure AKS | GCP GKE | Justificativa |
|----------|----------|-----------|---------|---------------|
| **Custo** | $105 ⭐⭐⭐⭐⭐ | $161 ⭐⭐⭐⭐ | $216 ⭐⭐⭐ | AKS balanceia custo/features |
| **SLA** | Manual (90%) | Nativo (99.9%) | Nativo (99.9%) | Produção precisa HA |
| **Auto-scaling** | ❌ | ✅ HPA | ✅ HPA | Essencial para picos |
| **Zero-downtime** | ❌ | ✅ Rolling | ✅ Rolling | Crítico para produção |
| **Rollback** | Manual | ✅ Automático | ✅ Automático | Reduz risco de deploy |
| **LGPD** | ✅ | ✅ | ✅ | Todas atendem |

**Decisão:**
```
✅ USE Azure AKS se:
   - SLA > 99% obrigatório
   - Auto-scaling necessário
   - Equipe tem expertise Kubernetes
   - Budget até $200/mês

⚠️ USE Azure VM APENAS se:
   - Budget < $120/mês (limitação severa)
   - Downtime de 1-2h aceitável
   - Equipe SEM expertise Kubernetes
```

**Documentação:** [terraform/azure/](../terraform/azure/)

---

### 2.3. Cenário: Produção Média (200-500GB/mês)

**Recomendação: Azure AKS - $280/mês** ✅

| Critério | Azure VM | Azure AKS | App Insights | Economia |
|----------|----------|-----------|--------------|----------|
| **Custo** | $180 | **$280** | $1,150 | **76% vs App Insights** |
| **Escalabilidade** | ❌ Manual | ✅ Auto (HPA) | ✅ Auto | AKS única opção viável |
| **Performance** | ⚠️ Degrada | ✅ Consistente | ✅ Consistente | VM não suporta carga |
| **HA** | ❌ Single point | ✅ Nativa | ✅ Gerenciada | VM não é confiável |

**Decisão:**
```
✅ USE Azure AKS:
   - Única opção viável para este volume
   - VM não escala adequadamente
   - Economia de 76% vs Application Insights
   - ROI em < 6 meses

❌ EVITE VM:
   - Performance degrada com 200GB+
   - Requer upgrade constante
   - Single point of failure
```

---

### 2.4. Cenário: High Scale (> 500GB/mês)

**Recomendação: Azure AKS - $450/mês** ✅ (única opção)

| Critério | Azure AKS | GCP GKE | App Insights | Decisão |
|----------|-----------|---------|--------------|---------|
| **Custo** | **$450** ⭐ | $550 | $2,300 | **80% economia vs App Insights** |
| **Escalabilidade** | ✅ 4+ nodes | ✅ 4+ nodes | ✅ Ilimitada | AKS/GKE obrigatórios |
| **Performance** | ✅ Excelente | ✅ Excelente | ✅ Excelente | Todas performam bem |
| **ROI** | < 3 meses | < 4 meses | Baseline | AKS break-even rápido |

**Decisão:**
```
✅ USE Azure AKS se:
   - 100% Azure ou Azure-first
   - Melhor custo ($450 vs $550 GKE)

✅ USE GCP GKE se:
   - Multi-cloud estratégico
   - GKE Autopilot preferível
   - Já usa GCP

❌ NUNCA Application Insights:
   - $2,300/mês é proibitivo
   - ROI do AKS em < 3 meses
```

---

## 3. Matriz de Decisão por Critério

### 3.1. Custo Total (3 anos)

| Opção | 100GB/mês | 500GB/mês | 1TB/mês | Total 3 anos (1TB) |
|-------|-----------|-----------|---------|-------------------|
| Azure VM | $3,780 | $6,480 | ❌ | ❌ Não escala |
| Azure AKS | $5,796 | $10,080 | **$16,200** ⭐ | **$16,200** |
| GCP GKE | $7,776 | $12,600 | $19,800 | $19,800 |
| App Insights | $8,280 | $41,400 | **$82,800** | **$82,800** ❌ |
| Managed Grafana | $9,396 | $13,680 | $23,400 | $23,400 |

**Economia AKS vs App Insights (3 anos, 1TB):**
- **$82,800 - $16,200 = $66,600 economizados (80%)** 💰

---

### 3.2. Complexidade de Gerenciamento

| Aspecto | VM | AKS/GKE | App Insights | Managed Grafana |
|---------|-----|---------|--------------|-----------------|
| **Setup Inicial** | 1-2h ⭐⭐⭐⭐⭐ | 4-8h ⭐⭐ | 15min ⭐⭐⭐⭐⭐ | 2-4h ⭐⭐⭐ |
| **Manutenção Semanal** | 2-4h | 1-2h | 0h | 1h |
| **Expertise Necessária** | Docker | Kubernetes | Azure | Kubernetes + Azure |
| **Atualizações** | Manual | Automáticas | Automáticas | Híbrido |
| **Troubleshooting** | SSH + logs | kubectl + logs | Portal | Portal + kubectl |
| **Documentação** | Média | Extensa | Extensa | Média |

**Recomendação:**
- Equipe < 3 pessoas SEM DevOps: VM (Dev) ou App Insights (Prod)
- Equipe 3-5 pessoas COM DevOps: AKS/GKE
- Equipe > 5 pessoas: AKS/GKE (melhor ROI)

---

### 3.3. LGPD/GDPR Compliance

| Requisito LGPD | VM | AKS/GKE | App Insights | Managed Grafana |
|----------------|-----|---------|--------------|-----------------|
| **Art. 6º - Finalidade** | ✅ Total | ✅ Total | ⚠️ Limitada | ⚠️ Limitada |
| **Art. 9º - Consentimento** | ✅ Logs | ✅ Logs | ✅ Logs | ✅ Logs |
| **Art. 15º - Acesso** | ✅ API | ✅ API | ⚠️ Portal | ⚠️ Portal |
| **Art. 18º - Exclusão** | ✅ API | ✅ API | ⚠️ Manual | ⚠️ Manual |
| **Art. 46º - Segurança** | ✅ AES-256 | ✅ AES-256 | ✅ Microsoft | ✅ Microsoft |
| **Sanitização (4 camadas)** | ✅ Total | ✅ Total | ❌ 1 camada | ⚠️ 2 camadas |
| **Retenção (90 dias)** | ✅ Config | ✅ Config | ⚠️ Pago | ✅ Config |
| **Data Residency** | ✅ Controle | ✅ Controle | ⚠️ Azure only | ⚠️ Azure only |

**Decisão LGPD:**
```
✅ LGPD CRÍTICO → Use VM ou AKS/GKE
   - Controle total sobre sanitização (4 camadas)
   - Retenção configurável (90 dias)
   - Data residency controlado
   - API de exclusão (direito ao esquecimento)

⚠️ LGPD MODERADO → Application Insights aceitável
   - 1 camada de sanitização (aplicação)
   - Retenção limitada
   - Dados em Azure (EUA ou Europa)
```

---

### 3.4. Escalabilidade e Performance

| Volume/dia | VM (1x) | VM (2x HA) | AKS (2 nodes) | AKS (4 nodes) | App Insights |
|------------|---------|------------|---------------|---------------|--------------|
| **3GB** (100GB/mês) | ✅ OK | ✅ OK | ✅ Overkill | ⭐ Overkill | ✅ OK |
| **16GB** (500GB/mês) | ⚠️ Lento | ✅ OK | ✅ Ideal | ⭐ Overkill | ✅ OK |
| **33GB** (1TB/mês) | ❌ Falha | ⚠️ Lento | ⚠️ Limite | ✅ Ideal | ✅ OK |
| **66GB** (2TB/mês) | ❌ | ❌ | ⚠️ Limite | ✅ OK | ⚠️ $4,600/mês |
| **100GB+** (3TB+/mês) | ❌ | ❌ | ⚠️ Max | ⚠️ 6+ nodes | ⚠️ $6,900+/mês |

**Latência p95 (ms):**
- VM (< 200GB): 50-100ms ✅
- VM (> 200GB): 200-500ms ⚠️ (degradação)
- AKS: 30-80ms ✅ (consistente)
- App Insights: 20-50ms ✅

---

## 4. Matriz de Decisão Final

### 4.1. Árvore de Decisão

```
INICIO: Qual o volume de logs/traces/métricas?

├─ < 50GB/mês
│  ├─ Orçamento ilimitado? → Application Insights ($115/mês)
│  └─ Orçamento limitado? → Azure VM ($105/mês)
│
├─ 50-100GB/mês
│  ├─ Dev/Stage? → Azure VM ($105/mês)
│  ├─ Produção + LGPD crítico? → Azure AKS ($161/mês)
│  └─ Produção simples? → Application Insights ($230/mês)
│
├─ 100-200GB/mês
│  ├─ Dev/Stage? → Azure VM ($105/mês)
│  ├─ Produção? → Azure AKS ($161/mês) ⭐ RECOMENDADO
│  └─ Multi-cloud? → GCP GKE ($216/mês)
│
├─ 200-500GB/mês
│  ├─ Azure? → Azure AKS ($280/mês) ⭐ ÚNICA OPÇÃO
│  └─ Multi-cloud? → GCP GKE ($350/mês)
│
└─ > 500GB/mês
   ├─ Azure? → Azure AKS ($450/mês) ⭐ ÚNICA OPÇÃO
   ├─ Multi-cloud? → GCP GKE ($550/mês)
   └─ ❌ NUNCA Application Insights ($1,150+/mês)
```

### 4.2. Scorecard Ponderado

Pesos: Custo (30%), Produção-Ready (25%), LGPD (20%), Setup (15%), Escalabilidade (10%)

| Opção | Custo | Prod-Ready | LGPD | Setup | Escala | **TOTAL** |
|-------|-------|------------|------|-------|--------|-----------|
| **Azure VM** | 10/10 ⭐ | 4/10 | 10/10 | 10/10 | 3/10 | **7.0/10** |
| **Azure AKS** | 8/10 | 10/10 ⭐ | 10/10 | 5/10 | 10/10 ⭐ | **8.6/10** ⭐ |
| **GCP GKE** | 7/10 | 10/10 | 10/10 | 5/10 | 10/10 | **8.1/10** |
| App Insights | 5/10 | 10/10 | 5/10 | 10/10 | 10/10 | **7.5/10** |
| Managed Grafana | 4/10 | 7/10 | 6/10 | 7/10 | 8/10 | **6.0/10** |

**Vencedor: Azure AKS (8.6/10)** - Melhor balanço custo/features/produção

---

## 5. Recomendações Finais por Perfil

### 5.1. Startup/Pequena Empresa (< 10 pessoas)

**Cenário:** Orçamento muito limitado, equipe pequena, MVP rápido

**Recomendação:**
1. **Início (MVP):** Application Insights ($115/mês)
   - Setup em 15 minutos
   - Zero gerenciamento
   
2. **Crescimento (> 100GB):** Azure VM ($105/mês)
   - Migrar quando LGPD se tornar crítico
   - Economiza 54% vs App Insights

3. **Escala (> 200GB):** Azure AKS ($161/mês)
   - Migrar quando precisar HA
   - Economiza 30-80% vs App Insights

### 5.2. Média Empresa (10-50 pessoas, 1-2 DevOps)

**Cenário:** Budget médio, equipe DevOps dedicada, requisitos LGPD

**Recomendação Direta:**
- **Azure AKS ($161/mês)** desde o início ⭐
  - Equipe DevOps já tem expertise Kubernetes
  - LGPD controlado desde o dia 1
  - Evita migrações futuras
  - ROI em < 6 meses vs App Insights

### 5.3. Grande Empresa (> 50 pessoas, equipe DevOps completa)

**Cenário:** Budget amplo, multi-cloud, compliance rigoroso

**Recomendação:**
- **Produção:** Azure AKS + GCP GKE (multi-cloud)
- **Dev/Stage:** Azure VM ou GCP VM
- **Monitoramento:** Grafana self-hosted
- **Custo Total (1TB):** $450-550/mês (economia de 75-80%)

---

## 6. 💰 Reserved Instances e Spot VMs - Economia Adicional

### 6.1. Modelos de Compra

**Reserved Instances (RI)** e **Committed Use Discounts (CUD)** são contratos de fidelidade que oferecem descontos significativos:

| Modelo | Custo Relativo | Desconto | Flexibilidade | Quando Usar |
|--------|----------------|----------|---------------|-------------|
| **Pay-As-You-Go** | 100% | 0% | ✅ Total | MVP, teste, workloads variáveis |
| **Reserva 1 Ano** | ~60% | 40% | ⚠️ Média | Produção estável (1 ano) |
| **Reserva 3 Anos** | ~35% | 65% | ❌ Baixa | Infraestrutura consolidada (3+ anos) |
| **Spot/Preemptible** | ~15% | 85% | ❌ Nula | Dev/Stage (aceita downtime) |

### 6.2. Economia 3 Anos: Azure vs GCP

| Cloud | Modelo | Custo 3Y | vs PAYG | vs App Insights |
|-------|--------|----------|---------|-----------------|
| **Azure** | Pay-As-You-Go | $8,244 | Baseline | 57% ↓ |
| **Azure** | **3 Year RI** ⭐ | **$6,084** | **26% ↓** | **68% ↓** |
| **Azure** | **Stage Spot** | **$6,228** | **24% ↓** | **67% ↓** |
| **GCP** | Pay-As-You-Go | $10,656 | Baseline | 46% ↓ |
| **GCP** | **Preemptible** ⭐ | **$8,316** | **22% ↓** | **58% ↓** |
| - | App Insights | $19,044 | - | Baseline |

**💰 Melhor Economia: Azure 3 Year RI = $6,084 (economia de $12,960 vs App Insights)**

### 6.3. Quando Usar Cada Modelo?

```
┌─────────────────────────────────────┐
│ Quanto tempo vai usar a infra?     │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
     < 6 meses       > 6 meses
       │                │
       ▼                ▼
   Pay-As-You-Go   Workload estável?
   (Flexível)           │
                 ┌──────┴──────┐
                 │             │
               Sim           Não
                 │             │
                 ▼             ▼
         Quanto tempo?    Pay-As-You-Go
                 │
         ┌───────┴────────┐
         │                │
      1-2 anos        3+ anos
         │                │
         ▼                ▼
     1 Year RI        3 Year RI
     (40% ↓)          (65% ↓) ⭐

É Dev/Stage com downtime OK?
         │
         ▼
Sim → Spot/Preemptible (85% ↓) ⭐⭐⭐
Não → Siga árvore acima
```

### 6.4. Como Provisionar

**Azure Spot VM:**
```bash
az vm create \
  --name vm-lgtm-stage-spot \
  --size Standard_D2s_v3 \
  --priority Spot \
  --max-price -1 \
  --eviction-policy Deallocate
```

**Azure Reserved Instance:**
```bash
# Portal: https://portal.azure.com → Reservations → Add
az reservations reservation-order purchase \
  --sku Standard_D2s_v3 \
  --term P1Y \
  --billing-plan Monthly
```

**GCP Preemptible (já no comando de criação VM):**
```bash
gcloud compute instances create lgtm-dev \
  --machine-type=e2-standard-2 \
  --preemptible  # Flag para Preemptible
```

**Detalhes:** [docs/visao_geral.md - Seção 5.8](visao_geral.md#58-reserved-instances-e-spot-vms---economia-adicional)

---

## 7. Checklist de Decisão

Use este checklist para validar sua escolha:

### ✅ Escolha Azure VM se:
- [ ] Volume < 200GB/mês
- [ ] Ambiente Dev/Stage (não-crítico)
- [ ] Orçamento < $120/mês
- [ ] Equipe SEM expertise Kubernetes
- [ ] Downtime de 1-2h aceitável
- [ ] LGPD crítico

### ✅ Escolha Azure AKS se:
- [ ] Volume > 100GB/mês
- [ ] Ambiente de Produção
- [ ] SLA > 99% obrigatório
- [ ] Auto-scaling necessário
- [ ] Equipe COM expertise Kubernetes
- [ ] LGPD crítico
- [ ] Budget até $200/mês (100GB) ou $500/mês (1TB)

### ✅ Escolha GCP GKE se:
- [ ] Multi-cloud estratégico
- [ ] Volume > 100GB/mês
- [ ] GKE Autopilot preferível
- [ ] Já usa GCP extensivamente
- [ ] LGPD crítico

### ⚠️ Escolha Application Insights se:
- [ ] Volume < 50GB/mês
- [ ] 100% Azure sem planos de mudança
- [ ] Equipe SEM DevOps dedicado
- [ ] Setup rápido > custo
- [ ] LGPD não é crítico
- [ ] Budget não é limitação

### ❌ NÃO escolha Azure Managed Grafana:
- [ ] Adiciona $100/mês sem reduzir complexidade
- [ ] Ainda precisa gerenciar AKS completo
- [ ] Use AKS self-hosted em vez disso

---

## 7. Próximos Passos

Após escolher sua opção:

### Opção 1: Azure VM
1. Ler [docs/deployment_vms.md](deployment_vms.md)
2. Provisionar VM Standard_D4s_v3
3. Instalar Docker + Docker Compose
4. Deploy stack LGTM
5. Configurar backend para OTLP
6. **Prazo:** 1-2 dias

### Opção 2: Azure AKS
1. Ler [terraform/azure/README.md](../terraform/azure/README.md)
2. Configurar Terraform
3. `terraform apply`
4. Configurar kubectl
5. Deploy via Helm
6. **Prazo:** 3-5 dias

### Opção 3: GCP GKE
1. Ler [terraform/gcp/README.md](../terraform/gcp/README.md)
2. Configurar Terraform
3. `terraform apply`
4. Configurar kubectl
5. Deploy via Helm
6. **Prazo:** 3-5 dias

---

## 9. Métricas de Sucesso

Após 30 dias de deployment, valide:

### Custo
- [ ] Custo real vs estimado (± 10%)
- [ ] Economia vs Application Insights (se aplicável)

### Performance
- [ ] Latência p95 < 100ms
- [ ] Taxa de erro < 1%
- [ ] Uptime > 99.5%

### LGPD
- [ ] Dados sensíveis sanitizados (CPF, email, etc.)
- [ ] Retenção configurada (90 dias)
- [ ] API de exclusão funcional

### Operacional
- [ ] Dashboards Grafana configurados
- [ ] Alertas Prometheus ativos
- [ ] Runbooks documentados
- [ ] Equipe treinada

---

## 10. Contato e Suporte

- **Documentação Completa:** [docs/visao_geral.md](visao_geral.md)
- **Deploy VMs:** [docs/deployment_vms.md](deployment_vms.md)
- **Deploy AKS:** [terraform/azure/README.md](../terraform/azure/README.md)
- **Deploy GKE:** [terraform/gcp/README.md](../terraform/gcp/README.md)
- **Issues:** GitHub Issues
- **Community:** https://community.grafana.com/

---

**Última atualização:** 2024-01-15  
**Versão:** 2.0  
**Autor:** Equipe POC LGTM
