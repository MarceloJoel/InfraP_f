# Variables Globales del Proyecto

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
  default     = "ares"
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "El entorno debe ser 'dev', 'stage' o 'prod'."
  }
}

# --- Red ---
variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_sn_cidrs" {
  description = "Rangos CIDR para las subredes públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_sn_cidrs" {
  description = "Rangos CIDR para las subredes privadas (app)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_sn_cidrs" {
  description = "Rangos CIDR para las subredes de base de datos"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# --- Base de Datos ---
variable "db_instance_class" {
  description = "Tipo de instancia para la BD RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento en GB para la BD RDS"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos a crear en RDS"
  type        = string
  default     = "aresdb"
}

variable "db_username" {
  description = "Usuario administrador de la BD RDS"
  type        = string
  default     = "admin"
}

# --- CI/CD y GitHub ---
variable "github_owner" {
  description = "Propietario (usuario u organización) del repositorio en GitHub."
  type        = string
}

variable "github_repo_infra" {
  description = "Nombre del repositorio de GitHub para el código de infraestructura."
  type        = string
}

variable "github_repo_app" {
  description = "Nombre del repositorio de GitHub para el código de la aplicación (frontend + backend)."
  type        = string
}

variable "github_branch" {
  description = "Nombre de la rama principal (ej. 'main' o 'master')."
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "El ARN de la conexión de AWS CodeStar a GitHub (creada manualmente en la consola)."
  type        = string
}

variable "frontend_app_path" {
  description = "Ruta relativa dentro del repo al build del frontend (ej. 'frontend/dist/app-name')"
  type        = string
  default     = "frontend/dist/angular-app" # Ajusta esto a tu proyecto
}

