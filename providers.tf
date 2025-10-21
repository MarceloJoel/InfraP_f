# =================================================================================
# Configuración del Proveedor y Backend Remoto
# =================================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # -------------------------------------------------------------------------------
  # Backend Remoto en S3 con Bloqueo en DynamoDB
  # Reemplaza 'your-terraform-state-bucket-name' y 'your-terraform-lock-table'
  # con los nombres de los recursos que creaste manualmente.
  # -------------------------------------------------------------------------------
  backend "s3" {
    bucket         = "ares-tfstate-marcelo-2025"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ares-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source para obtener el ID de la cuenta de AWS actual
data "aws_caller_identity" "current" {}
