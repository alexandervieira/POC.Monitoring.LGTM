#!/bin/bash

# Script para validar todos os ambientes sequencialmente

set -e

echo "========================================="
echo "  Validando todos os ambientes"
echo "========================================="
echo

ENVIRONMENTS=("dev" "stage" "prod")
FAILED=()

for env in "${ENVIRONMENTS[@]}"; do
    echo ""
    echo "========================================="
    echo "  Ambiente: $env"
    echo "========================================="
    
    if ./deploy-terraform.sh $env validate; then
        echo "✅ $env: OK"
    else
        echo "❌ $env: FALHOU"
        FAILED+=($env)
    fi
done

echo ""
echo "========================================="
echo "  Resumo da Validação"
echo "========================================="

if [ ${#FAILED[@]} -eq 0 ]; then
    echo "✅ Todos os ambientes validados com sucesso!"
else
    echo "❌ Ambientes com falha: ${FAILED[@]}"
    exit 1
fi