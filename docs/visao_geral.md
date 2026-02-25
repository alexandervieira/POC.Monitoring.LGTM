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

### 1.3. Comparação de Custos (Exemplo: 100GB/mês)

| Item | Stack LGTM (GCP) | Stack LGTM (Azure) | Application Insights |
|------|------------------|--------------------|--------------------|
| Ingestão | $0 (self-hosted) | $0 (self-hosted) | $230/mês |
| Storage | $20/mês (GCS) | $18/mês (Blob) | Incluído |
| Compute | $150/mês (GKE) | $140/mês (AKS) | N/A |
| **Total** | **$170/mês** | **$158/mês** | **$230/mês** |

**Economia com LGTM:** ~25-30% em escala

---

## 2. Stack LGTM no GCP vs Azure Managed Grafana

### 2.1. Stack LGTM Self-Hosted no GCP

**Arquitetura:**
```
Cloud Run (API) → OpenTelemetry Collector → GKE
                                              ├── Loki (logs)
                                              ├── Tempo (traces)
                                              ├── Prometheus (metrics)
                                              └── Grafana (visualização)
```

**Vantagens:**
- ✅ **Controle Total**: Configuração completa
- ✅ **Custo**: Mais barato em escala
- ✅ **LGPD**: Sanitização customizada
- ✅ **Performance**: Otimização dedicada

**Desvantagens:**
- ❌ **Gerenciamento**: Requer DevOps
- ❌ **Atualizações**: Manuais
- ❌ **HA**: Configuração complexa

**Custos Estimados (100GB/mês):**
- GKE (3 nodes n1-standard-2): $150/mês
- Cloud Storage: $20/mês
- Cloud SQL (PostgreSQL): $50/mês
- Load Balancer: $20/mês
- **Total: $240/mês**

### 2.2. Azure Managed Grafana + Stack LGTM

**Arquitetura:**
```
Container Apps (API) → OpenTelemetry Collector → AKS
                                                  ├── Loki (logs)
                                                  ├── Tempo (traces)
                                                  └── Prometheus (metrics)
                                                  
Azure Managed Grafana (visualização)
```

**Vantagens:**
- ✅ **Grafana Gerenciado**: Sem manutenção
- ✅ **Integração**: Nativa com Azure Monitor
- ✅ **HA**: Alta disponibilidade automática
- ✅ **Segurança**: Azure AD integrado

**Desvantagens:**
- ❌ **Custo**: Managed Grafana é caro
- ❌ **Limitações**: Menos plugins disponíveis
- ❌ **Vendor Lock-in**: Preso ao Azure

**Custos Estimados (100GB/mês):**
- AKS (3 nodes Standard_D2s_v3): $140/mês
- Azure Blob Storage: $18/mês
- Azure Database for PostgreSQL: $60/mês
- Azure Managed Grafana: $100/mês
- Load Balancer: $25/mês
- **Total: $343/mês**

### 2.3. Comparação Técnica

| Recurso | GCP Self-Hosted | Azure Managed Grafana |
|---------|-----------------|----------------------|
| Grafana | Self-managed | Managed |
| Loki | Self-managed | Self-managed |
| Tempo | Self-managed | Self-managed |
| Prometheus | Self-managed | Self-managed |
| HA | Manual | Automático (Grafana) |
| Backup | Manual | Automático (Grafana) |
| Atualizações | Manual | Automático (Grafana) |
| Custo | $240/mês | $343/mês |
| Complexidade | Alta | Média |

**Recomendação:**
- **GCP Self-Hosted**: Para equipes com DevOps experiente e orçamento limitado
- **Azure Managed Grafana**: Para equipes menores que priorizam simplicidade

---

## 3. LGPD: Sanitização e Anonimização

### 3.1. Estratégia de Sanitização

**Camadas de Proteção:**

1. **Aplicação (.NET)**
   - `SensitiveDataLogProcessor`: Sanitiza logs antes de enviar
   - `IncludeFormattedMessage = false`: Remove OriginalFormat
   - `ParseStateValues = false`: Remove state parsing

2. **OpenTelemetry Collector**
   - `transform/logs`: Sanitiza body com regex
   - `replace_all_patterns`: Sanitiza todos atributos
   - `attributes processor`: Deleta headers sensíveis

3. **Loki**
   - Retenção de 90 dias
   - Compactor para limpeza automática
   - API de exclusão para direito ao esquecimento

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

**Fluxo:**
```
1. Usuário faz login com CPF
2. Sistema gera SHA256(CPF) = user_hash
3. Logs usam user_hash (não CPF)
4. Tabela UserMapping armazena CPF criptografado (AES-256)
5. Após 90 dias ou solicitação: DELETE logs WHERE user_id = user_hash
```

**Exemplo:**
```csharp
var cpf = "123.456.789-10";
var userHash = SHA256(cpf); // "065af45fe97a5de193a1eb67511d454e9fdf950e29137dd220d91290df2a96c3"

// Log com hash
logger.LogInformation("Usuário {UserId} acessou", userHash);

// Query no Loki
{service_name="apicontagem", user_id="065af45fe97a5de193a1eb67511d454e9fdf950e29137dd220d91290df2a96c3"}

// Exclusão GDPR
DELETE FROM loki WHERE user_id = "065af45fe97a5de193a1eb67511d454e9fdf950e29137dd220d91290df2a96c3"
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

## 4. Retenção em Conformidade com LGPD

### 4.1. Configuração de Retenção

**Loki (90 dias):**
```yaml
limits_config:
  retention_period: 90d

compactor:
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
  delete_request_store: filesystem
```

**Tempo (90 dias):**
```yaml
storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks
    
compactor:
  compaction:
    block_retention: 2160h  # 90 dias
```

**PostgreSQL (90 dias):**
```sql
-- Job de limpeza automática
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
  DELETE FROM "HistoricoContagem" 
  WHERE "DataProcessamento" < NOW() - INTERVAL '90 days';
  
  DELETE FROM "UserMapping" 
  WHERE "RetentionUntil" < NOW();
END;
$$ LANGUAGE plpgsql;

-- Agendar execução diária
SELECT cron.schedule('cleanup-job', '0 2 * * *', 'SELECT cleanup_old_data()');
```

### 4.2. Processo de Exclusão (Direito ao Esquecimento)

**API Endpoint:**
```http
DELETE /gdpr/user/{cpf}
```

**Fluxo:**
1. Gerar user_hash do CPF
2. Deletar logs no Loki: `DELETE {user_id="hash"}`
3. Deletar traces no Tempo (via TTL automático)
4. Deletar dados no PostgreSQL
5. Deletar entrada na UserMapping
6. Retornar confirmação

**Tempo de Processamento:**
- Loki: Imediato (soft delete) + 2h (hard delete)
- Tempo: Até 90 dias (TTL)
- PostgreSQL: Imediato

### 4.3. Auditoria de Exclusão

```sql
CREATE TABLE "DeletionAudit" (
    "Id" SERIAL PRIMARY KEY,
    "UserHash" VARCHAR(64) NOT NULL,
    "RequestedAt" TIMESTAMP DEFAULT NOW(),
    "CompletedAt" TIMESTAMP,
    "Status" VARCHAR(20),
    "RequestedBy" VARCHAR(100)
);
```

---

## 5. Estimativas de Custos

### 5.1. GCP (Self-Hosted)

**Cenário: 100GB logs/mês, 50GB traces/mês, 10GB metrics/mês**

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| GKE Cluster | 3x n1-standard-2 (2 vCPU, 7.5GB RAM) | $150 |
| Cloud Storage | 160GB Standard | $26 |
| Cloud SQL | db-n1-standard-1 (PostgreSQL) | $50 |
| Load Balancer | 1 IP + tráfego | $20 |
| Cloud NAT | Tráfego de saída | $15 |
| **Total** | | **$261/mês** |

**Escalabilidade:**
- 500GB/mês: $450/mês
- 1TB/mês: $750/mês

### 5.2. Azure (Managed Grafana)

**Cenário: 100GB logs/mês, 50GB traces/mês, 10GB metrics/mês**

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| AKS Cluster | 3x Standard_D2s_v3 (2 vCPU, 8GB RAM) | $140 |
| Blob Storage | 160GB Hot tier | $25 |
| Azure Database | Standard B2s (PostgreSQL) | $60 |
| Managed Grafana | Standard tier | $100 |
| Load Balancer | Standard + tráfego | $30 |
| **Total** | | **$355/mês** |

**Escalabilidade:**
- 500GB/mês: $620/mês
- 1TB/mês: $1,050/mês

### 5.3. Application Insights (Azure)

**Cenário: 100GB logs/mês**

| Recurso | Especificação | Custo/mês |
|---------|---------------|-----------|
| Ingestão | 100GB @ $2.30/GB | $230 |
| Retenção | 90 dias (incluído) | $0 |
| Queries | Ilimitadas | $0 |
| **Total** | | **$230/mês** |

**Escalabilidade:**
- 500GB/mês: $1,150/mês
- 1TB/mês: $2,300/mês

### 5.4. Comparação de ROI

**Break-even Point (quando LGTM compensa):**

| Volume/mês | GCP LGTM | Azure LGTM | App Insights | Economia LGTM |
|------------|----------|------------|--------------|---------------|
| 50GB | $200 | $280 | $115 | -$85 |
| 100GB | $261 | $355 | $230 | +$0 |
| 200GB | $350 | $480 | $460 | +$110 |
| 500GB | $450 | $620 | $1,150 | +$700 |
| 1TB | $750 | $1,050 | $2,300 | +$1,550 |

**Conclusão:**
- **< 100GB/mês**: Application Insights é mais econômico
- **> 200GB/mês**: Stack LGTM é significativamente mais barato
- **> 500GB/mês**: Economia de 60-70% com LGTM

### 5.5. Custos Ocultos

**Stack LGTM:**
- DevOps: 20-40h/mês (setup + manutenção)
- Treinamento: 40h (one-time)
- Monitoramento: 10h/mês

**Application Insights:**
- Configuração: 5h (one-time)
- Manutenção: 2h/mês
- Treinamento: 10h (one-time)

---

## 6. Recomendações

### 6.1. Quando Usar Stack LGTM

✅ Volume > 200GB/mês  
✅ Multi-cloud ou migração futura  
✅ Requisitos rigorosos de LGPD  
✅ Equipe DevOps experiente  
✅ Necessidade de customização  
✅ Orçamento limitado em escala  

### 6.2. Quando Usar Application Insights

✅ Volume < 100GB/mês  
✅ 100% Azure  
✅ Equipe pequena sem DevOps  
✅ Necessidade de setup rápido  
✅ Orçamento não é limitação  
✅ Integração nativa com .NET  

### 6.3. Quando Usar Azure Managed Grafana

✅ Volume 100-500GB/mês  
✅ Equipe média com DevOps básico  
✅ Necessidade de Grafana gerenciado  
✅ Integração com Azure AD  
✅ Orçamento médio  

---

## 7. Próximos Passos

1. **POC**: Testar localmente com Docker Compose
2. **Piloto**: Deploy em ambiente de dev (GCP ou Azure)
3. **Validação**: Testar sanitização LGPD
4. **Produção**: Deploy gradual com monitoramento
5. **Otimização**: Ajustar retenção e custos
