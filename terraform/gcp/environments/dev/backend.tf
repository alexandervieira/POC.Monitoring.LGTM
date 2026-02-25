# Backend GCS para armazenar o estado do Terraform
terraform {
  backend "gcs" {
    bucket = "meu-projeto-dev-terraform-state"
    prefix = "dev"
    
    # Configurações recomendadas
    encryption_key = null  # Usar CMEK se necessário
    storage_class  = "STANDARD"
    
    # Versionamento do estado
    versioning = true
  }
}