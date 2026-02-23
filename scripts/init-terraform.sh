#!/bin/bash

# Script para inicializar Terraform em todos os ambientes

set -e

PROJECT_ID=${1:-$(gcloud config get-value project)}
REGION=${2:-us-central1}

echo "Initializing Terraform for project: $PROJECT_ID"
echo "Region: $REGION"

# Função para inicializar um ambiente
init_environment() {
  local env=$1
  local backend_bucket="${PROJECT_ID}-terraform-state-${env}"
  
  echo "========================================"
  echo "Initializing $env environment..."
  echo "========================================"
  
  cd ../terraform/environments/$env
  
  # Criar arquivo backend.tf temporário
  cat > backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "$backend_bucket"
    prefix = "$env"
  }
}
EOF
  
  # Inicializar Terraform
  terraform init \
    -backend-config="bucket=$backend_bucket" \
    -backend-config="prefix=$env" \
    -reconfigure
  
  # Validar configuração
  terraform validate
  
  # Formatar arquivos
  terraform fmt
  
  cd - > /dev/null
  
  echo "$env initialized successfully!"
}

# Inicializar recursos globais primeiro
echo "Initializing global resources..."
cd ../terraform/global

cat > backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-terraform-state-global"
    prefix = "global"
  }
}
EOF

terraform init \
  -backend-config="bucket=${PROJECT_ID}-terraform-state-global" \
  -backend-config="prefix=global" \
  -reconfigure

terraform validate
terraform fmt
cd - > /dev/null

echo "Global resources initialized successfully!"
echo ""

# Inicializar cada ambiente
init_environment "dev"
init_environment "stage"
init_environment "prod"

echo ""
echo "========================================"
echo "All environments initialized successfully!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. cd terraform/global && terraform plan"
echo "2. cd terraform/environments/dev && terraform plan"
echo "3. cd terraform/environments/stage && terraform plan"
echo "4. cd terraform/environments/prod && terraform plan"