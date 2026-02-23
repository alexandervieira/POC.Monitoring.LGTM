#!/bin/bash

# Configurações
ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-$(gcloud config get-value project)}
REGION="us-central1"

echo "Deploying backend for environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"

# Navegar para diretório do backend
cd ../backend

# Substituir variáveis no cloudbuild.yaml
sed "s/\${_ENVIRONMENT}/$ENVIRONMENT/g" cloudbuild.yaml > cloudbuild-$ENVIRONMENT.yaml

# Executar Cloud Build
gcloud builds submit \
  --config=cloudbuild-$ENVIRONMENT.yaml \
  --substitutions=_REGION=$REGION,_VPC_CONNECTOR=serverless-connector-$ENVIRONMENT \
  --project=$PROJECT_ID

# Verificar deploy
gcloud run services list \
  --platform=managed \
  --region=$REGION \
  --project=$PROJECT_ID \
  --filter="metadata.name=apicontagem-$ENVIRONMENT"

echo "Backend deployed successfully!"