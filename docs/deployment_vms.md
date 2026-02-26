# Guia de Deploy - Stack LGTM em VMs por Ambiente (Azure/GCP)

## 1. Visão Geral

Este guia detalha a implantação da Stack LGTM (Loki, Grafana, Tempo, Prometheus) em VMs por ambiente usando Docker Compose.

### 1.1. Recomendações por Ambiente

| Ambiente | Volume | Azure (Recomendado) | GCP | Quando Usar |
|----------|--------|---------------------|-----|-------------|
| **Dev** | < 50GB | **VM B2s ($90/mês)** ⭐ | VM Preemptible ($106) | Desenvolvimento local, downtime OK |
| **Stage** | 50-150GB | **VM D2s_v3 ($139/mês)** ⭐ | VM n1-standard-2 ($160) | Testes pré-prod, espelho prod |  
| **Prod** | > 150GB | **❌ Use AKS ($161)** | ❌ Use GKE ($216) | HA obrigatória, auto-scaling |

**⚠️ Importante:** Para **PRODUÇÃO**, use Kubernetes (AKS/GKE). VMs com HA custam 234-269% mais caro que K8s.

### 1.2. Quando Usar VMs

**✅ Use VMs para:**
- 🔵 Desenvolvimento (< 50GB/mês)
- 🟢 Staging (50-150GB/mês)
- 💰 Orçamento muito limitado
- 🚀 Setup rápido (< 2h)
- ⚙️ Equipe sem expertise Kubernetes

**❌ NÃO use VMs para:**
- 🔴 Produção com SLA > 99%
- 📈 Volume > 200GB/mês
- 🔄 Auto-scaling necessário
- 🛡️ Alta disponibilidade obrigatória

---

## 2. Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Cloud VNet/VPC                        │
│  ┌────────────────────────────────────────────────────┐ │
│  │         VM (4 vCPUs, 16GB RAM, 150GB SSD)          │ │
│  │                                                     │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │         Docker Compose Stack                  │ │ │
│  │  │                                                │ │ │
│  │  │  ┌────────────────────────────────────────┐  │ │ │
│  │  │  │  OpenTelemetry Collector (LGPD)        │  │ │ │
│  │  │  │  - Transform processor                 │  │ │ │
│  │  │  │  - Attributes delete                   │  │ │ │
│  │  │  └──────────┬─────────────────────────────┘  │ │ │
│  │  │             │                                 │ │ │
│  │  │    ┌────────┴────────┬──────────┬─────────┐ │ │ │
│  │  │    ▼                 ▼          ▼         ▼ │ │ │
│  │  │  ┌────┐          ┌─────┐    ┌────┐   ┌────┐│ │ │
│  │  │  │Loki│          │Tempo│    │Prom│   │Graf││ │ │
│  │  │  │:3100│         │:3200│    │:9090│  │:3000││ │ │
│  │  │  └────┘          └─────┘    └────┘   └────┘│ │ │
│  │  │                                              │ │ │
│  │  │  Volumes:                                    │ │ │
│  │  │  - /data/loki  (logs)                        │ │ │
│  │  │  - /data/tempo (traces)                      │ │ │
│  │  │  - /data/prometheus (metrics)                │ │ │
│  │  │  - /data/grafana (dashboards)                │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  Public IP: XX.XX.XX.XX                                  │
│  - Grafana: http://XX.XX.XX.XX:3000                      │
│  - OTLP Receiver: http://XX.XX.XX.XX:4317                │
└──────────────────────────────────────────────────────────┘
            │               │          │
            ▼               ▼          ▼
    ┌───────────────────────────────────────────┐
    │   Cloud Storage (90d lifecycle)           │
    │  - Azure Blob Storage LRS                 │
    │  - Google Cloud Storage Standard          │
    └───────────────────────────────────────────┘
```

---

## 3. Pré-requisitos

### 3.1. Azure
```bash
# Azure CLI
az --version  # >= 2.50.0

# Login
az login

# Criar resource group
az group create \
  --name rg-lgtm-vm-dev \
  --location eastus
```

### 3.2. GCP
```bash
# gcloud CLI
gcloud --version  # >= 400.0.0

# Login
gcloud auth login

# Configurar projeto
gcloud config set project <PROJECT_ID>
```

---

## 4. Provisionar VM por Ambiente

### 4.1. DEV - Azure Standard_B2s ($90/mês) ⭐ RECOMENDADO

**Especificações Técnicas:**

```yaml
VM: Standard_B2s
  vCPUs: 2
  RAM: 4 GB
  Storage: 100GB Standard SSD (P10)
  CPU: Intel Xeon Platinum 8370C (2.8 GHz base)
  Network: 2 Gbps
  Max IOPS: 2,300 (burst 5,000)
  Créditos CPU: 40% base + acumula até 100% em idle
  
Docker Stack (alocar 3.5GB):
  - Grafana: 512MB RAM
  - Loki: 1GB RAM
  - Tempo: 512MB RAM  
  - Prometheus: 1GB RAM
  - OpenTelemetry Collector: 256MB RAM
  - Sistema Operacional: 500MB (buffer)

Sistema:
  OS: Ubuntu 22.04 LTS
  Docker: 24.0.7
  Compose: 2.21.0
```

**Capacidades:**
- Volume suportado: < 50GB/mês
- Downtime: 1-2h/mês (aceitável)
- Burst CPU: 100% créditos para picos de 2-3h
- Ideal para desenvolvimento local

```bash
# Criar VM Ubuntu 22.04 (B2s)
az vm create \
  --resource-group rg-lgtm-vm-dev \
  --name vm-lgtm-dev \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --public-ip-address-dns-name lgtm-dev \
  --os-disk-size-gb 100 \
  --storage-sku StandardSSD_LRS

# Abrir portas
az vm open-port --resource-group rg-lgtm-vm-dev --name vm-lgtm-dev --port 3000 --priority 1001  # Grafana
az vm open-port --resource-group rg-lgtm-vm-dev --name vm-lgtm-dev --port 4317 --priority 1002  # OTLP gRPC
az vm open-port --resource-group rg-lgtm-vm-dev --name vm-lgtm-dev --port 4318 --priority 1003  # OTLP HTTP

# Conectar via SSH
PUBLIC_IP=$(az vm show --resource-group rg-lgtm-vm-dev --name vm-lgtm-dev --query publicIps -d -o tsv)
ssh azureuser@$PUBLIC_IP
```

**Custo total Dev: $90/mês**
- VM B2s: $30/mês
- Disk 100GB Standard SSD: $5/mês
- PostgreSQL B1ms: $30/mês
- Container Instance: $12/mês
- Blob Storage 60GB: $8/mês
- Public IP: $5/mês

---

### 4.2. STAGE - Azure Standard_D2s_v3 ($139/mês) ⭐ RECOMENDADO

**Especificações Técnicas:**

```yaml
VM: Standard_D2s_v3
  vCPUs: 2
  RAM: 8 GB
  Storage: 120GB Premium SSD (P6)
  CPU: Intel Xeon E5-2673 v4 (2.3 GHz base, 3.5 GHz turbo)
  Network: Moderate (5 Gbps)
  Max IOPS: 3,500
  Performance: Consistente (sem burst, 100% sempre)
  
Docker Stack (alocar 7GB):
  - Grafana: 1GB RAM
  - Loki: 2GB RAM
  - Tempo: 1.5GB RAM
  - Prometheus: 2GB RAM
  - OpenTelemetry Collector: 512MB RAM
  - Sistema Operacional: 1GB (buffer + cache)

Sistema:
  OS: Ubuntu 22.04 LTS
  Docker: 24.0.7
  Compose: 2.21.0
  Monitoring: Azure Monitor Agent
```

**Capacidades:**
- Volume suportado: 50-150GB/mês
- Espelho de produção (mesma config)
- Premium SSD com IOPS previsível
- Performance consistente 24/7

```bash
# Criar VM Ubuntu 22.04 (D2s_v3)
az vm create \
  --resource-group rg-lgtm-vm-stage \
  --name vm-lgtm-stage \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --public-ip-address-dns-name lgtm-stage \
  --os-disk-size-gb 120 \
  --storage-sku Premium_LRS

# Abrir portas (mesmos comandos do dev)
az vm open-port --resource-group rg-lgtm-vm-stage --name vm-lgtm-stage --port 3000 --priority 1001
az vm open-port --resource-group rg-lgtm-vm-stage --name vm-lgtm-stage --port 4317 --priority 1002
az vm open-port --resource-group rg-lgtm-vm-stage --name vm-lgtm-stage --port 4318 --priority 1003

# Conectar via SSH
PUBLIC_IP=$(az vm show --resource-group rg-lgtm-vm-stage --name vm-lgtm-stage --query publicIps -d -o tsv)
ssh azureuser@$PUBLIC_IP
```

**Custo total Stage: $139/mês**
- VM D2s_v3: $70/mês
- Disk 120GB Premium SSD: $10/mês
- PostgreSQL B1ms: $30/mês
- Container Instance: $12/mês
- Blob Storage 100GB: $12/mês
- Public IP: $5/mês

---

### 4.3. GCP Alternativa

#### Dev - e2-standard-2 com Preemptible ($106/mês)

**Especificações Técnicas:**

```yaml
VM: e2-standard-2 (Preemptible)
  vCPUs: 2
  RAM: 8 GB
  Storage: 100GB Persistent Disk SSD
  CPU: Intel/AMD (compartilhado)
  Network: Até 4 Gbps
  Max IOPS: 15,000 reads / 10,000 writes
  Availability: 99.0% (pode ser interrompida)
  
Docker Stack (alocar 5GB):
  - Grafana: 512MB RAM
  - Loki: 1.5GB RAM
  - Tempo: 1GB RAM
  - Prometheus: 1.5GB RAM
  - OpenTelemetry Collector: 256MB RAM
  - Sistema Operacional: 3GB (buffer generoso)

Sistema:
  OS: Ubuntu 22.04 LTS
  Docker: 24.0.7
  Compose: 2.21.0
  Monitoring: Cloud Monitoring Agent
```

```bash
# Criar VM Ubuntu 22.04 (e2-standard-2, PREEMPTIBLE)
gcloud compute instances create lgtm-dev \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --preemptible \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-standard \
  --tags=lgtm-dev

# Criar firewall rules
gcloud compute firewall-rules create allow-grafana-dev \
  --allow=tcp:3000 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=lgtm-dev

gcloud compute firewall-rules create allow-otlp-dev \
  --allow=tcp:4317,tcp:4318 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=lgtm-dev

# Conectar via SSH
gcloud compute ssh lgtm-dev --zone=us-central1-a
```

**⚠️ Preemptible:** VM pode ser interrompida pelo GCP (ok para dev)

#### Stage - n1-standard-2 ($160/mês)

**Especificações Técnicas:**

```yaml
VM: n1-standard-2
  vCPUs: 2
  RAM: 7.5 GB
  Storage: 120GB Persistent Disk SSD
  CPU: Intel Xeon (Skylake, Broadwell, Haswell)
  Network: Até 10 Gbps
  Max IOPS: 25,000 reads / 15,000 writes
  Availability: 99.5%
  
Docker Stack (alocar 7GB):
  - Grafana: 1GB RAM
  - Loki: 2GB RAM
  - Tempo: 1.5GB RAM
  - Prometheus: 2GB RAM
  - OpenTelemetry Collector: 512MB RAM
  - Sistema Operacional: 500MB (buffer)

Sistema:
  OS: Ubuntu 22.04 LTS
  Docker: 24.0.7
  Compose: 2.21.0
  Monitoring: Cloud Monitoring Agent
  Logging: Cloud Logging Agent
```

```bash
# Criar VM Ubuntu 22.04 (n1-standard-2)
gcloud compute instances create lgtm-stage \
  --zone=us-central1-a \
  --machine-type=n1-standard-2 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=120GB \
  --boot-disk-type=pd-ssd \
  --tags=lgtm-stage

# Firewall rules (mesmos do dev)
gcloud compute firewall-rules create allow-grafana-stage \
  --allow=tcp:3000 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=lgtm-stage

gcloud compute firewall-rules create allow-otlp-stage \
  --allow=tcp:4317,tcp:4318 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=lgtm-stage

# Conectar via SSH
gcloud compute ssh lgtm-stage --zone=us-central1-a
```

---

## 5. Instalar Dependências

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Instalar Docker Compose
sudo apt install docker-compose-plugin -y

# Verificar instalação
docker --version
docker compose version
```

---

## 6. Configurar Stack LGTM

### 6.1. Criar Estrutura de Diretórios

```bash
# Criar diretórios
mkdir -p ~/lgtm-stack/{config,data/{loki,tempo,prometheus,grafana}}
cd ~/lgtm-stack

# Criar volumes persistentes
sudo chown -R 10001:10001 data/loki      # Loki user
sudo chown -R 10001:10001 data/tempo     # Tempo user
sudo chown -R 472:472 data/grafana       # Grafana user
sudo chown -R 65534:65534 data/prometheus # Prometheus nobody
```

### 6.2. docker-compose.yml

Crie `~/lgtm-stack/docker-compose.yml`:

```yaml
version: '3.8'

networks:
  lgtm:
    driver: bridge

volumes:
  loki-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/loki
  tempo-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/tempo
  prometheus-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/prometheus
  grafana-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/grafana

services:
  # OpenTelemetry Collector (LGPD Sanitization)
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.91.0
    container_name: otel-collector
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./config/otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8888:8888"   # Metrics
      - "8889:8889"   # Prometheus exporter
    networks:
      - lgtm
    restart: unless-stopped

  # Loki - Log Aggregation
  loki:
    image: grafana/loki:2.9.3
    container_name: loki
    command: -config.file=/etc/loki/loki-config.yaml
    volumes:
      - ./config/loki-config.yaml:/etc/loki/loki-config.yaml
      - loki-data:/loki
    ports:
      - "3100:3100"
    networks:
      - lgtm
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3100/ready"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Tempo - Distributed Tracing
  tempo:
    image: grafana/tempo:2.3.1
    container_name: tempo
    command: ["-config.file=/etc/tempo/tempo-config.yaml"]
    volumes:
      - ./config/tempo-config.yaml:/etc/tempo/tempo-config.yaml
      - tempo-data:/tmp/tempo
    ports:
      - "3200:3200"   # Tempo HTTP
      - "4320:4317"   # OTLP gRPC (internal)
    networks:
      - lgtm
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3200/ready"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Prometheus - Metrics
  prometheus:
    image: prom/prometheus:v2.48.1
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - lgtm
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Grafana - Visualization
  grafana:
    image: grafana/grafana:10.2.3
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana-data:/var/lib/grafana
      - ./config/grafana-datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml
    ports:
      - "3000:3000"
    networks:
      - lgtm
    restart: unless-stopped
    depends_on:
      - loki
      - tempo
      - prometheus
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 6.3. Configurações

#### config/otel-collector-config.yaml

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

  # LGPD: Sanitizar dados sensíveis em logs
  transform/logs:
    log_statements:
      - context: log
        statements:
          # CPF: 123.456.789-10
          - replace_pattern(body, "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "***CPF-REDACTED***")
          # Email: user@email.com
          - replace_pattern(body, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "***EMAIL-REDACTED***")
          # Telefone: (11) 98765-4321
          - replace_pattern(body, "\\(?\\d{2}\\)?\\s?9?\\d{4}-?\\d{4}", "***PHONE-REDACTED***")
          # Cartão: 4111 1111 1111 1111
          - replace_pattern(body, "\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}", "***CARD-REDACTED***")
          # CNPJ: 12.345.678/0001-90
          - replace_pattern(body, "\\d{2}\\.\\d{3}\\.\\d{3}/\\d{4}-\\d{2}", "***CNPJ-REDACTED***")
          # JWT: eyJhbGci...
          - replace_pattern(body, "eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+", "***JWT-REDACTED***")
          
          # Sanitizar attributes também
          - replace_all_patterns(attributes, "value", "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "***CPF-REDACTED***")
          - replace_all_patterns(attributes, "value", "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "***EMAIL-REDACTED***")

  # LGPD: Remover headers sensíveis
  attributes/delete:
    actions:
      - key: http.request.header.authorization
        action: delete
      - key: http.request.header.cookie
        action: delete
      - key: http.response.header.set-cookie
        action: delete

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls:
      insecure: true

  loki:
    endpoint: http://loki:3100/loki/api/v1/push
    tls:
      insecure: true

  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: otelcol

  logging:
    loglevel: info

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/tempo]
    
    logs:
      receivers: [otlp]
      processors: [transform/logs, attributes/delete, batch]
      exporters: [loki]
    
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
```

#### config/loki-config.yaml

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2023-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

compactor:
  working_directory: /loki/boltdb-shipper-compactor
  shared_store: filesystem
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150

limits_config:
  retention_period: 2160h  # 90 dias
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 2160h
```

#### config/tempo-config.yaml

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317

ingester:
  trace_idle_period: 10s
  max_block_bytes: 1_000_000
  max_block_duration: 5m

compactor:
  compaction:
    block_retention: 2160h  # 90 dias

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/blocks
    wal:
      path: /tmp/tempo/wal
    pool:
      max_workers: 100
      queue_depth: 10000
```

#### config/prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'lgtm-vm'
    environment: 'dev'

scrape_configs:
  # OpenTelemetry Collector metrics
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8888']
        labels:
          service: 'otel-collector'

  # OpenTelemetry Collector Prometheus exporter
  - job_name: 'otel-prometheus'
    static_configs:
      - targets: ['otel-collector:8889']

  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Loki metrics
  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  # Tempo metrics
  - job_name: 'tempo'
    static_configs:
      - targets: ['tempo:3200']

  # Grafana metrics
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
```

#### config/grafana-datasources.yaml

```yaml
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    jsonData:
      maxLines: 1000

  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
    isDefault: false
    jsonData:
      nodeGraph:
        enabled: true
      serviceMap:
        enabled: true

  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      timeInterval: 30s
```

---

## 7. Deploy

```bash
# Navegar para o diretório
cd ~/lgtm-stack

# Iniciar stack
docker compose up -d

# Verificar containers
docker compose ps

# Ver logs
docker compose logs -f

# Verificar health
docker compose ps | grep "healthy"
```

**Resultado esperado:**
```
NAME             STATUS          PORTS
otel-collector   Up              0.0.0.0:4317-4318->4317-4318/tcp
loki             Up (healthy)    0.0.0.0:3100->3100/tcp
tempo            Up (healthy)    0.0.0.0:3200->3200/tcp
prometheus       Up (healthy)    0.0.0.0:9090->9090/tcp
grafana          Up (healthy)    0.0.0.0:3000->3000/tcp
```

---

## 8. Validar Instalação

### 8.1. Grafana
```bash
# Acessar: http://<PUBLIC_IP>:3000
# Login: admin / admin

# Verificar datasources
curl http://localhost:3000/api/datasources
```

### 8.2. Prometheus
```bash
# Acessar: http://<PUBLIC_IP>:9090
curl http://localhost:9090/api/v1/targets
```

### 8.3. OpenTelemetry Collector
```bash
# Verificar métricas
curl http://localhost:8888/metrics

# Testar envio OTLP
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans": []}'
```

---

## 9. Configurar Backend API (.NET 10)

No seu `Program.cs`:

```csharp
// Configurar OpenTelemetry
builder.Services.AddOpenTelemetry()
    .UseOtlpExporter(opt =>
    {
        opt.Endpoint = new Uri("http://<PUBLIC_IP>:4317");
        opt.Protocol = OtlpExportProtocol.Grpc;
    })
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddEntityFrameworkCoreInstrumentation())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation())
    .WithLogging(logging => logging
        .AddOtlpExporter());
```

---

## 10. Monitoramento e Manutenção

### 10.1. Ver Logs
```bash
# Logs de todos os containers
docker compose logs -f

# Logs específicos
docker compose logs -f grafana
docker compose logs -f loki
docker compose logs -f tempo
docker compose logs -f prometheus
docker compose logs -f otel-collector
```

### 10.2. Reiniciar Serviços
```bash
# Reiniciar todos
docker compose restart

# Reiniciar específico
docker compose restart grafana
```

### 10.3. Atualizar Stack
```bash
# Pull de novas imagens
docker compose pull

# Recriar containers
docker compose up -d
```

### 10.4. Backup de Dados
```bash
# Criar backup
sudo tar -czf lgtm-backup-$(date +%Y%m%d).tar.gz data/

# Restaurar backup
sudo tar -xzf lgtm-backup-20240101.tar.gz
```

### 10.5. Monitorar Uso de Disco
```bash
# Ver uso de volumes Docker
docker system df -v

# Limpar dados antigos (cuidado!)
docker system prune -a --volumes
```

---

## 11. Custos Detalhados por Ambiente

### 11.1. Azure - Dev (Standard_B2s)

| Recurso | Especificação | Custo/mês | Anual |
|---------|---------------|-----------|-------|
| VM | Standard_B2s (2vCPU, 4GB) | $30 | $360 |
| Managed Disk | 100GB Standard SSD | $5 | $60 |
| Public IP | Standard | $5 | $60 |
| Blob Storage | 60GB LRS + lifecycle | $8 | $96 |
| PostgreSQL | B_Standard_B1ms | $30 | $360 |
| Container Instance | 1 app, 0.25 vCPU | $12 | $144 |
| Static Web App | Free tier | $0 | $0 |
| **Total Dev** | | **$90/mês** ⭐ | **$1,080/ano** |

### 11.2. Azure - Stage (Standard_D2s_v3)

| Recurso | Especificação | Custo/mês | Anual |
|---------|---------------|-----------|-------|
| VM | Standard_D2s_v3 (2vCPU, 8GB) | $70 | $840 |
| Managed Disk | 120GB Premium SSD | $10 | $120 |
| Public IP | Standard | $5 | $60 |
| Blob Storage | 100GB LRS + lifecycle | $12 | $144 |
| PostgreSQL | B_Standard_B1ms | $30 | $360 |
| Container Instance | 1 app, 0.25 vCPU | $12 | $144 |
| Static Web App | Free tier | $0 | $0 |
| **Total Stage** | | **$139/mês** ⭐ | **$1,668/ano** |

### 11.3. GCP - Dev (e2-standard-2 Preemptible)

| Recurso | Especificação | Custo/mês | Anual |
|---------|---------------|-----------|-------|
| VM | e2-standard-2 Preemptible (2vCPU, 8GB) | $20 | $240 |
| Persistent Disk | 100GB Standard | $15 | $180 |
| Static IP | 1 IP | $6 | $72 |
| Cloud Storage | 60GB Standard + lifecycle | $10 | $120 |
| Cloud SQL | db-f1-micro | $40 | $480 |
| Cloud Run | 1 service, 0.25 vCPU | $15 | $180 |
| Firebase Hosting | Free tier | $0 | $0 |
| **Total Dev** | | **$106/mês** | **$1,272/ano** |

**⚠️ Preemptible:** VM pode ser interrompida (ok para dev)

### 11.4. GCP - Stage (n1-standard-2)

| Recurso | Especificação | Custo/mês | Anual |
|---------|---------------|-----------|-------|
| VM | n1-standard-2 (2vCPU, 7.5GB) | $50 | $600 |
| Persistent Disk | 120GB SSD | $18 | $216 |
| Static IP | 1 IP | $6 | $72 |
| Cloud Storage | 100GB Standard + lifecycle | $16 | $192 |
| Cloud SQL | db-n1-standard-1 | $50 | $600 |
| Cloud Run | 1 service, 0.25 vCPU | $20 | $240 |
| Firebase Hosting | Free tier | $0 | $0 |
| **Total Stage** | | **$160/mês** | **$1,920/ano** |

### 11.5. Comparativo Total (Dev + Stage)

| Setup | Dev/mês | Stage/mês | Total/mês | Total/ano | Economia vs App Insights |
|-------|---------|-----------|-----------|-----------|-------------------------|
| **Azure VMs** ⭐ | $90 | $139 | **$229** | **$2,748** | **57%** |
| GCP VMs | $106 | $160 | $266 | $3,192 | 50% |
| Application Insights | $230 | $299 | $529 | $6,348 | Baseline |

**Economia Azure VMs:** $3,600/ano ($300/mês)

### 11.6. 💰 Reserved Instances & Spot VMs - Economia Adicional

**Reserved Instances (RI)** e **Committed Use Discounts (CUD)** são "contratos de fidelidade" que oferecem descontos significativos:

#### Modelos de Compra

| Modelo | Custo | Desconto | Flexibilidade | Risco |
|--------|-------|----------|---------------|-------|
| **Pay-As-You-Go** | 100% | 0% | ✅ Total (liga/desliga quando quiser) | ✅ Zero |
| **Reserva 1 Ano** | ~60% | 40% | ⚠️ Média (compromisso 1 ano) | ⚠️ Baixo |
| **Reserva 3 Anos** | ~30-40% | 60-70% | ❌ Baixa (compromisso 3 anos) | ⚠️ Médio |
| **Spot/Preemptible** | ~10-20% | 80-90% | ❌ Nula (cloud pode desligar) | ❌ Alto |

#### Azure - With Reserved Instances

**Dev (Standard_B2s):**

| Modelo | VM | Outros | **Total/mês** | **3 Anos** | Economia |
|--------|-----|--------|---------------|------------|----------|
| Pay-As-You-Go | $30 | $60 | **$90** | $3,240 | Baseline |
| 1 Year RI | $18 | $60 | **$78** | $2,808 | 13% ↓ |
| 3 Year RI | $12 | $60 | **$72** | $2,592 | 20% ↓ |

**⚠️ B-series não suporta Spot/Preemptible**

**Stage (Standard_D2s_v3):**

| Modelo | VM | Outros | **Total/mês** | **3 Anos** | Economia |
|--------|-----|--------|---------------|------------|----------|
| **Pay-As-You-Go** | $70 | $69 | **$139** | $5,004 | Baseline |
| **1 Year RI** | $42 | $69 | **$111** | $3,996 | 20% ↓ |
| **3 Year RI** | $28 | $69 | **$97** | $3,492 | 30% ↓ |
| **Spot** ⭐ | $14 | $69 | **$83** | $2,988 | **40% ↓** |

#### GCP - With Committed Use Discounts

**Dev (e2-standard-2 Preemptible):**

| Modelo | VM | Outros | **Total/mês** | **3 Anos** | Economia |
|--------|-----|--------|---------------|------------|----------|
| Pay-As-You-Go | $50 | $86 | $136 | $4,896 | Baseline |
| 1 Year CUD | $34 | $86 | $120 | $4,320 | 12% ↓ |
| 3 Year CUD | $24 | $86 | $110 | $3,960 | 19% ↓ |
| **Preemptible** ⭐ | $20 | $86 | **$106** | $3,816 | **22% ↓** |

**Stage (n1-standard-2):**

| Modelo | VM | Outros | **Total/mês** | **3 Anos** | Economia |
|--------|-----|--------|---------------|------------|----------|
| Pay-As-You-Go | $50 | $110 | **$160** | $5,760 | Baseline |
| 1 Year CUD | $34 | $110 | **$144** | $5,184 | 10% ↓ |
| 3 Year CUD | $24 | $110 | **$134** | $4,824 | 16% ↓ |
| **Preemptible** | $15 | $110 | **$125** | $4,500 | **22% ↓** |

#### Comparativo: Dev + Stage (3 Anos)

| Cloud | Modelo | Dev 3Y | Stage 3Y | **Total 3Y** | vs PAYG | vs App Insights |
|-------|--------|--------|----------|--------------|---------|-----------------|
| Azure | Pay-As-You-Go | $3,240 | $5,004 | **$8,244** | Baseline | 57% ↓ |
| **Azure** | **3 Year RI** ⭐ | $2,592 | $3,492 | **$6,084** | **26% ↓** | **68% ↓** |
| **Azure** | **Stage Spot** | $3,240 | $2,988 | **$6,228** | **24% ↓** | **67% ↓** |
| GCP | Pay-As-You-Go | $4,896 | $5,760 | **$10,656** | Baseline | 46% ↓ |
| GCP | 3 Year CUD | $3,960 | $4,824 | **$8,784** | 18% ↓ | 56% ↓ |
| **GCP** | **Preemptible** | $3,816 | $4,500 | **$8,316** | **22% ↓** | **58% ↓** |
| - | App Insights | $8,280 | $10,764 | **$19,044** | - | Baseline |

**💰 Melhor Economia 3 Anos:**
1. **Azure 3 Year RI: $6,084** - Economia de $12,960 vs App Insights (68%)
2. **Azure Stage Spot: $6,228** - Economia de $12,816 vs App Insights (67%)
3. **GCP Preemptible: $8,316** - Economia de $10,728 vs App Insights (58%)

#### Como Provisionar com Reserved Instances

**Azure - Comprar Reserved Instance:**

```bash
# Listar ofertas de RI disponíveis
az reservations catalog show \
  --reserved-resource-type VirtualMachines \
  --location eastus

# Comprar 1 Year RI para Standard_D2s_v3
az reservations reservation-order purchase \
  --reservation-order-id <order-id> \
  --sku Standard_D2s_v3 \
  --location eastus \
  --quantity 1 \
  --term P1Y \
  --billing-plan Monthly

# Ou via Portal Azure:
# https://portal.azure.com → Reservations → Add
```

**Azure - Usar Spot VM:**

```bash
# Criar VM com Spot (D2s_v3)
az vm create \
  --resource-group rg-lgtm-vm-stage \
  --name vm-lgtm-stage-spot \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --size Standard_D2s_v3 \
  --priority Spot \
  --max-price -1 \
  --eviction-policy Deallocate \
  --admin-username azureuser \
  --generate-ssh-keys
```

**GCP - Comprar Committed Use Discount:**

```bash
# Listar ofertas de CUD
gcloud compute commitments list

# Comprar 1 Year CUD para n1-standard-2
gcloud compute commitments create lgtm-cud-1y \
  --plan 12-month \
  --resources vcpu=2,memory=8 \
  --region us-central1

# Ou via Console:
# https://console.cloud.google.com → Compute Engine → Committed use discounts
```

**GCP - Preemptible já está no comando de criação da VM anterior (flag `--preemptible`).**

#### Quando Usar Cada Modelo?

| Cenário | Recomendação | Justificativa |
|---------|--------------|---------------|
| **MVP/Teste (< 6 meses)** | Pay-As-You-Go | Máxima flexibilidade, pode desligar |
| **Produção estável (1 ano)** | 1 Year RI/CUD | 40% desconto, compromisso aceitável |
| **Infraestrutura consolidada (3+ anos)** | 3 Year RI/CUD | 60-70% desconto, melhor economia |
| **Dev com downtime OK** | **Spot/Preemptible** ⭐ | **80-90% desconto**, aceita interrupções |
| **Stage com redundância** | **Spot/Preemptible** ⭐ | Economia máxima, CI/CD resiliente |

#### ⚠️ Atenção: Spot/Preemptible

**Vantagens:**
- ✅ 80-90% desconto
- ✅ Ideal para Dev/Stage não-crítico
- ✅ Azure: Previsão de 30s antes de desligar
- ✅ GCP: Tentativa de 30s de graceful shutdown

**Desvantagens:**
- ❌ Pode ser desligada a qualquer momento
- ❌ Não recomendado para Prod
- ❌ Requer automação de redeploy

**Setup com Spot/Preemptible:**

```bash
# (Exemplo Azure) Script de monitoramento e redeploy automático
# ~/monitor-spot.sh

#!/bin/bash
while true; do
  VM_STATE=$(az vm get-instance-view \
    --resource-group rg-lgtm-vm-stage \
    --name vm-lgtm-stage-spot \
    --query instanceView.statuses[1].code -o tsv)
  
  if [ "$VM_STATE" != "PowerState/running" ]; then
    echo "VM stopped, redeploying..."
    az vm start \
      --resource-group rg-lgtm-vm-stage \
      --name vm-lgtm-stage-spot
  fi
  
  sleep 60  # Check every minute
done
```

---

## 12. ⚠️ Alta Disponibilidade - NÃO RECOMENDADO para VMs

**Importante:** Para **PRODUÇÃO**, use Kubernetes (AKS/GKE) em vez de VMs com HA.

### 12.1. Por que VMs com HA são mais caras?

| Setup | Custo/mês | HA | Auto-scaling | Recomendação |
|-------|-----------|-----|--------------|--------------|
| **Azure AKS** | **$161** ✅ | ✅ Nativa | ✅ HPA | ✅ **USE ISSO** |
| **GCP GKE** | **$216** ✅ | ✅ Nativa | ✅ HPA | ✅ Multi-cloud |
| Azure VMs HA | $538 ❌ | ⚠️ Manual | ❌ | ❌ 234% mais caro |
| GCP VMs HA | $582 ❌ | ⚠️ Manual | ❌ | ❌ 269% mais caro |

### 12.2. Custo VMs com HA (apenas referência)

**Azure HA (2x D4s_v3 + Load Balancer):**
- 2x Standard_D4s_v3 (4vCPU, 16GB): $280
- 2x Managed Disk (150GB Premium): $30
- Load Balancer: $20
- PostgreSQL GP_Standard_D2s_v3: $150
- Blob Storage: $18
- Container Apps (HA): $40
- **Total: $538/mês** (234% mais caro que AKS)

**GCP HA (2x n1-standard-4 + Load Balancer):**
- 2x n1-standard-4 (4vCPU, 15GB): $280
- 2x Persistent Disk (150GB SSD): $36
- Load Balancer + IP: $20
- Cloud SQL HA (db-n1-standard-2): $180
- Cloud Storage: $26
- Cloud Run (HA): $40
- **Total: $582/mês** (169% mais caro que GKE)

### 12.3. Conclusão: Use Kubernetes para Produção

**VMs são recomendadas APENAS para:**
- 🔵 Dev (< 50GB): Azure VM B2s ($90)
- 🟢 Stage (50-150GB): Azure VM D2s_v3 ($139)

**Produção (> 150GB): Use Kubernetes**
- 🔴 Azure AKS: $161/mês (64% mais barato que VMs HA)
- 🔴 GCP GKE: $216/mês (63% mais barato que VMs HA)

---

## 13. Troubleshooting

### 13.1. Container não inicia
```bash
# Ver logs detalhados
docker compose logs <service-name>

# Verificar configuração
docker compose config

# Reiniciar do zero
docker compose down -v
docker compose up -d
```

### 13.2. Grafana não acessa Loki/Tempo
```bash
# Testar conectividade
docker compose exec grafana ping loki
docker compose exec grafana ping tempo

# Verificar network
docker network inspect lgtm-stack_lgtm
```

### 13.3. Disco cheio
```bash
# Ver uso de disco
df -h

# Limpar logs antigos do Docker
sudo journalctl --vacuum-time=7d

# Compactar dados Loki (manual)
docker compose exec loki /usr/bin/loki -config.file=/etc/loki/loki-config.yaml -target=compactor
```

### 13.4. Alta latência
```bash
# Monitorar recursos
htop

# Ver uso de disco I/O
iostat -x 1

# Considerar upgrade para:
# - Azure: Standard_D8s_v3 (8 vCPUs, 32GB) +$60/mês
# - GCP: n1-standard-8 (8 vCPUs, 30GB) +$70/mês
```

---

## 14. Próximos Passos

1. ✅ **VM provisionada** e stack LGTM rodando
2. ✅ **Sanitização LGPD** configurada no OTel Collector
3. 🔄 **Configurar backend API** para enviar telemetria
4. 🔄 **Importar dashboards Grafana**:
   - [ASP.NET Core Metrics - ID 19924](https://grafana.com/grafana/dashboards/19924)
   - [ASP.NET Core Endpoint - ID 19925](https://grafana.com/grafana/dashboards/19925)
5. 🔄 **Configurar alertas** no Prometheus
6. 🔄 **Testar LGPD** com dados sensíveis
7. 🔄 **Documentar runbooks** de operação

---

## 15. Migração para AKS/GKE

Quando o volume crescer (> 200GB/mês) ou precisar de HA:

1. **Export dashboards Grafana**:
```bash
curl http://localhost:3000/api/dashboards/db/my-dashboard | jq > dashboard.json
```

2. **Backup de dados**:
```bash
sudo tar -czf lgtm-migration.tar.gz data/
```

3. **Deploy no AKS/GKE** usando Terraform (ver `/terraform/azure` ou `/terraform/gcp`)

4. **Import dashboards**:
```bash
kubectl create configmap grafana-dashboards --from-file=dashboard.json -n monitoring
```

**Custo após migração**:
- Azure VM ($105) → Azure AKS ($161) = +$56/mês (+53%)
- GCP VM ($120) → GCP GKE ($216) = +$96/mês (+80%)

**Benefícios**:
- ✅ Auto-scaling
- ✅ Alta disponibilidade
- ✅ Zero-downtime deploys
- ✅ Suporta > 500GB/mês

---

## 16. Recursos Adicionais

- **Documentação Oficial**:
  - [Grafana Loki](https://grafana.com/docs/loki/latest/)
  - [Grafana Tempo](https://grafana.com/docs/tempo/latest/)
  - [Prometheus](https://prometheus.io/docs/)
  - [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)

- **Comparação com outras opções**:
  - Ver `/docs/visao_geral.md` - Seção 5 (Custos)
  - Ver `/docs/visao_geral.md` - Seção 6 (Recomendações)

- **Suporte**:
  - Issues: GitHub Issues
  - Grafana Community: https://community.grafana.com/

---

**Desenvolvido com ❤️ usando Docker Compose + Stack LGTM**
