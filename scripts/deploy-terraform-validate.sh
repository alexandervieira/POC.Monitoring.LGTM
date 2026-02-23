#!/bin/bash

# Script para deploy do Terraform por ambiente com validação completa

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para validar dependências
check_dependencies() {
    log_info "Verificando dependências..."
    
    # Verificar terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform não encontrado. Por favor, instale o Terraform >= 1.6.0"
        exit 1
    fi
    
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: $TERRAFORM_VERSION"
    
    # Verificar gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud SDK não encontrado. Por favor, instale o gcloud"
        exit 1
    fi
    
    GCLOUD_VERSION=$(gcloud version | head -n1)
    log_info "Google Cloud SDK: $GCLOUD_VERSION"
    
    # Verificar jq (para parsing JSON)
    if ! command -v jq &> /dev/null; then
        log_warning "jq não encontrado. Algumas funcionalidades podem ser limitadas."
    fi
    
    log_success "Todas as dependências estão instaladas"
}

# Função para validar autenticação GCP
check_gcp_auth() {
    log_info "Verificando autenticação GCP..."
    
    # Verificar se está logado
    if ! gcloud auth print-access-token &> /dev/null; then
        log_error "Não autenticado no GCP. Execute 'gcloud auth login' primeiro."
        exit 1
    fi
    
    # Verificar projeto ativo
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$CURRENT_PROJECT" ]; then
        log_error "Nenhum projeto GCP configurado. Execute 'gcloud config set project PROJECT_ID'"
        exit 1
    fi
    
    log_info "Projeto ativo: $CURRENT_PROJECT"
    
    # Verificar se o projeto existe e está acessível
    if ! gcloud projects describe $CURRENT_PROJECT &> /dev/null; then
        log_error "Projeto $CURRENT_PROJECT não encontrado ou sem acesso"
        exit 1
    fi
    
    log_success "Autenticação GCP OK"
}

# Função para validar arquivos Terraform
validate_terraform_files() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Validando arquivos Terraform para ambiente: $env"
    
    # Verificar se diretório existe
    if [ ! -d "$terraform_dir" ]; then
        log_error "Diretório $terraform_dir não encontrado"
        exit 1
    fi
    
    cd "$terraform_dir"
    
    # Verificar arquivos obrigatórios
    local required_files=("main.tf" "variables.tf" "terraform.tfvars" "backend.tf")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Arquivo obrigatório não encontrado: $file"
            exit 1
        fi
    done
    
    # Verificar sintaxe dos arquivos .tf
    log_info "Verificando sintaxe dos arquivos Terraform..."
    if ! terraform fmt -check -recursive; then
        log_warning "Arquivos Terraform não estão formatados corretamente. Execute 'terraform fmt -recursive' para corrigir."
        read -p "Deseja continuar mesmo assim? (s/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
    
    cd - > /dev/null
    log_success "Arquivos Terraform validados para $env"
}

# Função para validar variáveis de ambiente
validate_env_vars() {
    local env=$1
    
    log_info "Validando variáveis de ambiente para $env..."
    
    # Verificar variáveis obrigatórias
    case $env in
        prod)
            if [ -z "$TF_VAR_kms_key_id" ]; then
                log_warning "TF_VAR_kms_key_id não definido. Verifique se CMEK está configurado."
            fi
            if [ -z "$TF_VAR_api_version" ]; then
                log_error "TF_VAR_api_version é obrigatório para produção"
                exit 1
            fi
            ;;
        stage)
            if [ -z "$TF_VAR_api_version" ]; then
                log_warning "TF_VAR_api_version não definido. Usando 'latest'."
                export TF_VAR_api_version="latest"
            fi
            ;;
    esac
    
    log_success "Variáveis de ambiente validadas"
}

# Função principal de validação Terraform
run_terraform_validation() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Executando validação completa do Terraform para $env..."
    
    cd "$terraform_dir"
    
    # 1. Inicialização
    log_info "1. Inicializando Terraform..."
    if ! terraform init -backend=false -reconfigure > /dev/null 2>&1; then
        log_error "Falha na inicialização do Terraform"
        terraform init -backend=false
        exit 1
    fi
    log_success "Inicialização concluída"
    
    # 2. Validação
    log_info "2. Validando configuração..."
    if ! terraform validate; then
        log_error "Falha na validação do Terraform"
        terraform validate
        exit 1
    fi
    log_success "Configuração válida"
    
    # 3. Formatação (opcional)
    log_info "3. Verificando formatação..."
    if ! terraform fmt -check -recursive; then
        log_warning "Arquivos não formatados. Execute 'terraform fmt -recursive'"
    else
        log_success "Formatação OK"
    fi
    
    # 4. Validação de variáveis
    log_info "4. Validando variáveis..."
    if ! terraform validate -var-file="terraform.tfvars" > /dev/null 2>&1; then
        log_error "Falha na validação com terraform.tfvars"
        terraform validate -var-file="terraform.tfvars"
        exit 1
    fi
    log_success "Variáveis válidas"
    
    # 5. Verificação de providers
    log_info "5. Verificando providers..."
    if ! terraform providers lock -platform=linux_amd64 -platform=darwin_amd64; then
        log_warning "Falha ao gerar lock de providers. Continuando..."
    else
        log_success "Providers OK"
    fi
    
    # 6. Validação de outputs
    log_info "6. Verificando outputs..."
    if ! terraform output -json > /dev/null 2>&1; then
        # Pode falhar se não houver estado ainda, ignorar
        log_warning "Não foi possível validar outputs (estado pode não existir)"
    else
        log_success "Outputs OK"
    fi
    
    cd - > /dev/null
    log_success "Validação completa para $env"
}

# Função para validar backend
validate_backend() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Validando backend para $env..."
    
    cd "$terraform_dir"
    
    # Extrair bucket do backend
    BACKEND_BUCKET=$(grep -A5 'backend "gcs"' backend.tf | grep bucket | cut -d'"' -f2)
    
    if [ -n "$BACKEND_BUCKET" ]; then
        log_info "Backend bucket: $BACKEND_BUCKET"
        
        # Verificar se bucket existe
        if ! gsutil ls "gs://$BACKEND_BUCKET" &> /dev/null; then
            log_warning "Bucket $BACKEND_BUCKET não encontrado. Será criado durante o init?"
        else
            log_success "Bucket backend OK"
            
            # Verificar permissões
            if gsutil iam get "gs://$BACKEND_BUCKET" &> /dev/null; then
                log_success "Permissões do bucket OK"
            else
                log_warning "Não foi possível verificar permissões do bucket"
            fi
        fi
    else
        log_warning "Não foi possível identificar o bucket backend"
    fi
    
    cd - > /dev/null
}

# Função para executar plano
run_terraform_plan() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Executando terraform plan para $env..."
    
    cd "$terraform_dir"
    
    # Inicializar com backend
    terraform init -reconfigure
    
    # Selecionar workspace
    terraform workspace select $env 2>/dev/null || terraform workspace new $env
    
    # Gerar plano
    PLAN_FILE="tfplan-${env}-$(date +%Y%m%d-%H%M%S)"
    
    if [ "$env" == "prod" ]; then
        # Para produção, gerar plano detalhado
        terraform plan \
            -var-file="terraform.tfvars" \
            -detailed-exitcode \
            -out="$PLAN_FILE" \
            -input=false
        PLAN_EXIT_CODE=$?
    else
        terraform plan \
            -var-file="terraform.tfvars" \
            -out="$PLAN_FILE" \
            -input=false
        PLAN_EXIT_CODE=$?
    fi
    
    case $PLAN_EXIT_CODE in
        0)
            log_success "Nenhuma alteração necessária para $env"
            ;;
        1)
            log_error "Erro no terraform plan para $env"
            exit 1
            ;;
        2)
            log_warning "Alterações detectadas no plano para $env"
            
            # Salvar plano em JSON para análise
            terraform show -json "$PLAN_FILE" > "../../plans/${PLAN_FILE}.json"
            log_info "Plano salvo em: ../../plans/${PLAN_FILE}.json"
            
            # Mostrar resumo das alterações
            echo "Resumo das alterações:"
            terraform show "$PLAN_FILE" | grep -E "(create|destroy|modify)" | sort | uniq -c
            ;;
    esac
    
    # Salvar caminho do plano para uso posterior
    echo "$PLAN_FILE" > "../../plans/latest-${env}.txt"
    
    cd - > /dev/null
}

# Função para aplicar plano
run_terraform_apply() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Executando terraform apply para $env..."
    
    cd "$terraform_dir"
    
    # Verificar se existe plano
    PLAN_FILE=$(cat "../../plans/latest-${env}.txt" 2>/dev/null || echo "")
    
    if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
        log_warning "Nenhum plano encontrado. Executando plan primeiro..."
        run_terraform_plan $env
        PLAN_FILE=$(cat "../../plans/latest-${env}.txt")
    fi
    
    # Confirmar apply
    if [ "$env" == "prod" ]; then
        echo -e "${RED}ATENÇÃO: Aplicando alterações em PRODUÇÃO!${NC}"
        read -p "Digite o nome do ambiente para confirmar (prod): " CONFIRM
        if [ "$CONFIRM" != "prod" ]; then
            log_error "Confirmação falhou. Abortando."
            exit 1
        fi
        
        # Aprovação adicional para produção
        read -p "Você fez backup do estado atual? (s/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_error "Backup não confirmado. Abortando."
            exit 1
        fi
    else
        read -p "Deseja aplicar as alterações? (s/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_info "Apply cancelado"
            cd - > /dev/null
            exit 0
        fi
    fi
    
    # Aplicar
    if ! terraform apply "$PLAN_FILE"; then
        log_error "Falha no terraform apply para $env"
        exit 1
    fi
    
    log_success "Apply concluído para $env"
    
    # Mostrar outputs
    terraform output
    
    cd - > /dev/null
}

# Função para destruir recursos (com proteção)
run_terraform_destroy() {
    local env=$1
    local terraform_dir="../terraform/environments/$env"
    
    log_info "Executando terraform destroy para $env..."
    
    cd "$terraform_dir"
    
    # Proteção para produção
    if [ "$env" == "prod" ]; then
        log_error "Destroy em produção não é permitido via script!"
        log_error "Para destruir produção, execute manualmente com aprovação adequada."
        exit 1
    fi
    
    # Confirmação adicional
    echo -e "${RED}ATENÇÃO: Isso destruirá TODOS os recursos do ambiente $env!${NC}"
    read -p "Digite o nome do ambiente para confirmar ($env): " CONFIRM
    if [ "$CONFIRM" != "$env" ]; then
        log_error "Confirmação falhou. Abortando."
        exit 1
    fi
    
    # Backup do estado
    log_info "Fazendo backup do estado atual..."
    terraform state pull > "../../backups/state-${env}-$(date +%Y%m%d-%H%M%S).json"
    log_success "Backup realizado"
    
    # Destroy
    terraform destroy -auto-approve
    
    log_success "Destroy concluído para $env"
    
    cd - > /dev/null
}

# Função para gerar relatório de validação
generate_validation_report() {
    local env=$1
    local report_file="../reports/validation-${env}-$(date +%Y%m%d-%H%M%S).md"
    
    log_info "Gerando relatório de validação para $env..."
    
    mkdir -p ../reports
    
    cat > "$report_file" << EOF
# Relatório de Validação Terraform - $env

**Data:** $(date '+%Y-%m-%d %H:%M:%S')
**Projeto:** $(gcloud config get-value project)
**Usuário:** $(whoami)

## Ambiente: $env

### Validações Realizadas

- [x] Dependências instaladas
- [x] Autenticação GCP
- [x] Arquivos Terraform
- [x] Variáveis de ambiente
- [x] Validação Terraform
- [x] Backend GCS

### Resultados

$(cd "../terraform/environments/$env" && terraform version)

### Recursos Planejados

\`\`\`
$(cd "../terraform/environments/$env" && terraform plan -no-color -detailed-exitcode 2>&1 || true)
\`\`\`

### Próximos Passos

1. Revisar as alterações planejadas
2. Executar apply com aprovação
3. Validar outputs após deploy
4. Executar testes de integração

---
Relatório gerado automaticamente pelo script deploy-terraform.sh
EOF
    
    log_success "Relatório gerado: $report_file"
}

# Função principal
main() {
    local ENVIRONMENT=$1
    local ACTION=$2
    
    echo "========================================="
    echo "  Terraform Deploy Script"
    echo "========================================="
    echo
    
    # Validar argumentos
    if [ -z "$ENVIRONMENT" ] || [ -z "$ACTION" ]; then
        log_error "Uso: $0 <environment> <action>"
        echo "Environments: dev, stage, prod"
        echo "Actions: validate, plan, apply, destroy, all"
        echo ""
        echo "Exemplos:"
        echo "  $0 dev validate    # Apenas validação"
        echo "  $0 stage plan      # Plano para staging"
        echo "  $0 prod apply      # Apply em produção (cuidado!)"
        echo "  $0 dev all         # Validação + plano + apply"
        exit 1
    fi
    
    # Validar ambiente
    case $ENVIRONMENT in
        dev|stage|prod)
            log_info "Ambiente: $ENVIRONMENT"
            ;;
        *)
            log_error "Ambiente inválido: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    # Criar diretórios necessários
    mkdir -p ../terraform/plans ../terraform/backups ../reports
    
    # Executar ações
    case $ACTION in
        validate)
            check_dependencies
            check_gcp_auth
            validate_terraform_files $ENVIRONMENT
            validate_env_vars $ENVIRONMENT
            run_terraform_validation $ENVIRONMENT
            validate_backend $ENVIRONMENT
            generate_validation_report $ENVIRONMENT
            ;;
        plan)
            check_dependencies
            check_gcp_auth
            validate_terraform_files $ENVIRONMENT
            validate_env_vars $ENVIRONMENT
            run_terraform_validation $ENVIRONMENT
            validate_backend $ENVIRONMENT
            run_terraform_plan $ENVIRONMENT
            generate_validation_report $ENVIRONMENT
            ;;
        apply)
            check_dependencies
            check_gcp_auth
            run_terraform_apply $ENVIRONMENT
            ;;
        destroy)
            run_terraform_destroy $ENVIRONMENT
            ;;
        all)
            check_dependencies
            check_gcp_auth
            validate_terraform_files $ENVIRONMENT
            validate_env_vars $ENVIRONMENT
            run_terraform_validation $ENVIRONMENT
            validate_backend $ENVIRONMENT
            run_terraform_plan $ENVIRONMENT
            generate_validation_report $ENVIRONMENT
            run_terraform_apply $ENVIRONMENT
            ;;
        *)
            log_error "Ação inválida: $ACTION"
            exit 1
            ;;
    esac
    
    log_success "Script concluído para $ENVIRONMENT"
}

# Executar função principal
main "$@"