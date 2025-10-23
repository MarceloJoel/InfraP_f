# Configuración de los Proveedores y Backend Remoto

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Usamos una versión reciente del provider de AWS
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Para generar cadenas aleatorias (ej. contraseña de BD)
    }
  }

  # -------------------------------------------------------------------------------
  # Backend Remoto en S3 con Bloqueo en DynamoDB
  # REEMPLAZA los valores de 'bucket' y 'dynamodb_table'
  # con los nombres de los recursos que creaste manualmente (Requisito #3 del README).
  # -------------------------------------------------------------------------------
  backend "s3" {
    bucket         = "reemplazame-tfstate-bucket"  # <-- REEMPLAZA ESTO
    key            = "global/s3/terraform.tfstate" # Puedes dejar esta línea como está
    region         = "us-east-1"
    dynamodb_table = "reemplazame-terraform-locks" # <-- REEMPLAZA ESTO
    encrypt        = true                          # Siempre encripta el estado
  }
}

# Proveedor de AWS principal (para todos los recursos regionales)
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Proveedor de AWS en us-east-1 (para CloudFront)
# Requerido aunque no usemos ACM, ya que CloudFront es un servicio global
# que se gestiona mejor desde us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

