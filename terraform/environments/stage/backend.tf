terraform {
  backend "gcs" {
    bucket = "meu-projeto-stage-terraform-state"
    prefix = "stage"
    
    # Configurações de segurança
    encryption_key = null  # Usar CMEK em produção
    
    # Versionamento do estado
    versioning = true
    
    # Impedir deleção acidental
    force_destroy = false
  }
}