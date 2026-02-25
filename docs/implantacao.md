# Guia de Implantação - Stack LGTM + LGPD

## 0. Instalação de Ferramentas no Windows 11

### 0.1. Docker Desktop
```powershell
# Download e instalação
# 1. Baixar: https://www.docker.com/products/docker-desktop/
# 2. Executar instalador
# 3. Reiniciar o computador
# 4. Verificar instalação
docker --version
docker-compose --version
```

### 0.2. .NET 10 SDK
```powershell
# Download e instalação
# 1. Baixar: https://dotnet.microsoft.com/download/dotnet/10.0
# 2. Executar instalador dotnet-sdk-10.0-win-x64.exe
# 3. Verificar instalação
dotnet --version
```

### 0.3. Git
```powershell
# Download e instalação
# 1. Baixar: https://git-scm.com/download/win
# 2. Executar instalador Git-2.43.0-64-bit.exe
# 3. Verificar instalação
git --version
```

### 0.4. Terraform
```powershell
# Via Chocolatey (recomendado)
choco install terraform

# Ou manual:
# 1. Baixar: https://www.terraform.io/downloads
# 2. Extrair terraform.exe para C:\terraform
# 3. Adicionar ao PATH: setx PATH "%PATH%;C:\terraform"
# 4. Verificar instalação
terraform --version
```

### 0.5. Azure CLI
```powershell
# Download e instalação
# 1. Baixar: https://aka.ms/installazurecliwindows
# 2. Executar instalador azure-cli.msi
# 3. Verificar instalação
az --version

# Login
az login
```

### 0.6. Google Cloud SDK
```powershell
# Download e instalação
# 1. Baixar: https://cloud.google.com/sdk/docs/install
# 2. Executar instalador GoogleCloudSDKInstaller.exe
# 3. Verificar instalação
gcloud --version

# Login
gcloud auth login
gcloud auth application-default login
```

### 0.7. kubectl
```powershell
# Via Azure CLI
az aks install-cli

# Ou via Chocolatey
choco install kubernetes-cli

# Verificar instalação
kubectl version --client
```

### 0.8. Helm
```powershell
# Via Chocolatey
choco install kubernetes-helm

# Ou manual:
# 1. Baixar: https://github.com/helm/helm/releases
# 2. Extrair helm.exe para C:\helm
# 3. Adicionar ao PATH
# 4. Verificar instalação
helm version
```

### 0.9. k6 (Testes de Carga)
```powershell
# Via Chocolatey
choco install k6

# Ou manual:
# 1. Baixar: https://github.com/grafana/k6/releases
# 2. Extrair k6.exe para C:\k6
# 3. Adicionar ao PATH
# 4. Verificar instalação
k6 version
```

### 0.10. Visual Studio Code (Opcional)
```powershell
# Download e instalação
# 1. Baixar: https://code.visualstudio.com/
# 2. Executar instalador VSCodeUserSetup-x64.exe
# 3. Instalar extensões recomendadas:
#    - C# Dev Kit
#    - Docker
#    - Terraform
#    - Kubernetes
```

### 0.11. Configurar WSL2 (Recomendado)
```powershell
# Habilitar WSL2
wsl --install

# Instalar Ubuntu
wsl --install -d Ubuntu-22.04

# Configurar Docker para usar WSL2
# Docker Desktop > Settings > General > Use WSL 2 based engine
```

## 1. Pré-requisitos

### Ferramentas Necessárias
```bash
# Docker & Docker Compose
docker --version  # >= 24.0
docker-compose --version  # >= 2.20

# .NET SDK
dotnet --version  # >= 10.0

# Terraform
terraform --version  # >= 1.6

# Helm
helm version  # >= 3.12

# kubectl
kubectl version  # >= 1.28

# Azure CLI (para Azure)
az --version  # >= 2.50

# gcloud CLI (para GCP)
gcloud --version  # >= 450.0
```

[... resto do conteúdo permanece igual ...]
