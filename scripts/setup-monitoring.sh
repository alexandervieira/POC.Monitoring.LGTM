#!/bin/bash

# Configurações
ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-$(gcloud config get-value project)}
REGION="us-central1"
CLUSTER_NAME="$ENVIRONMENT-lgtm-cluster"

echo "Setting up monitoring stack for environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"

# Obter credentials do cluster
gcloud container clusters get-credentials $CLUSTER_NAME \
  --region=$REGION \
  --project=$PROJECT_ID

# Criar namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Criar secret para acesso ao GCS (Workload Identity)
kubectl annotate serviceaccount -n monitoring default \
  iam.gke.io/gcp-service-account=$ENVIRONMENT-lgtm-sa@$PROJECT_ID.iam.gserviceaccount.com

# Aplicar ConfigMap do Alloy
kubectl apply -f ../k8s/configmaps/alloy-config.yaml

# Instalar/atualizar Helm chart
cd ../k8s/helm/lgtm-stack

# Atualizar dependências
helm dependency update

# Instalar com values específicos do ambiente
helm upgrade --install lgtm-stack . \
  --namespace monitoring \
  --values values/$ENVIRONMENT.yaml \
  --set global.gcpProjectId=$PROJECT_ID \
  --set global.storageBucket=$PROJECT_ID-$ENVIRONMENT-loki-logs \
  --wait \
  --timeout 10m

# Verificar pods
kubectl get pods -n monitoring

echo "Monitoring stack deployed successfully!"