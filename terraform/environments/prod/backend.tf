terraform {
  backend "gcs" {
    bucket = "meu-projeto-prod-terraform-state"
    prefix = "prod"
    
    # CMEK para o estado do Terraform
    encryption_key = "projects/meu-projeto-prod-12345/locations/us-central1/keyRings/terraform/cryptoKeys/state-key"
    
    # Versionamento obrigatório
    versioning = true
    
    # Impedir deleção acidental
    force_destroy = false
    
    # Object holds para proteção adicional
    object_holds = true
    
    # Retenção do estado
    retention_policy = {
      retention_period = 7776000  # 90 dias
      is_locked        = true
    }
  }
}