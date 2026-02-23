#!/bin/bash

# Configurações
ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-$(gcloud config get-value project)}

echo "Deploying frontend for environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"

# Navegar para diretório do frontend
cd ../frontend

# Instalar dependências
npm ci

# Criar arquivo .env
cat > .env << EOF
REACT_APP_GRAFANA_URL=https://grafana-$ENVIRONMENT.$PROJECT_ID.web.app
REACT_APP_ENVIRONMENT=$ENVIRONMENT
EOF

# Build
npm run build

# Deploy para Firebase
firebase use $PROJECT_ID
firebase target:apply hosting frontend-$ENVIRONMENT $PROJECT_ID-$ENVIRONMENT
firebase deploy --only hosting:frontend-$ENVIRONMENT

echo "Frontend deployed successfully!"
echo "URL: https://$PROJECT_ID-$ENVIRONMENT.web.app"