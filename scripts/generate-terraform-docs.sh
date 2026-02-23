#!/bin/bash

# Script para gerar documentação do Terraform

set -e

echo "Gerando documentação do Terraform..."

# Verificar se terraform-docs está instalado
if ! command -v terraform-docs &> /dev/null; then
    echo "terraform-docs não encontrado. Instalando..."
    curl -sSLo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
    tar -xzf terraform-docs.tar.gz
    chmod +x terraform-docs
    sudo mv terraform-docs /usr/local/bin/
fi

# Gerar docs para módulos
for module in terraform/modules/*; do
    if [ -d "$module" ]; then
        echo "Gerando docs para módulo: $(basename $module)"
        terraform-docs markdown table --output-file README.md --output-mode inject $module
    fi
done

# Gerar docs para ambientes
for env in terraform/environments/*; do
    if [ -d "$env" ]; then
        echo "Gerando docs para ambiente: $(basename $env)"
        terraform-docs markdown table --output-file README.md --output-mode inject $env
    fi
done

echo "Documentação gerada com sucesso!"