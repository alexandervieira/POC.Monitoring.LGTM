#!/bin/bash

# Script para deploy do Terraform por ambiente

set -e

ENVIRONMENT=$1
ACTION=$2  # plan, apply, destroy

if [ -z "$ENVIRONMENT" ] || [ -z "$ACTION" ]; then
    echo "Usage: $0 <environment> <action>"
    echo "Environments: dev, stage, prod"
    echo "Actions: plan, apply, destroy"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
echo "Deploying to environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo "Action: $ACTION"

cd ../terraform/environments/$ENVIRONMENT

# Inicializar Terraform
terraform init -reconfigure

# Selecionar workspace (opcional)
terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT

# Executar ação
case $ACTION in
    plan)
        terraform plan -out=tfplan
        ;;
    apply)
        terraform apply tfplan
        ;;
    destroy)
        terraform destroy
        ;;
    *)
        echo "Invalid action: $ACTION"
        exit 1
        ;;
esac

echo "Terraform $ACTION completed for $ENVIRONMENT"