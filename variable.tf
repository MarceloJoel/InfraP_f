# =================================================================================
# Variables de Entrada Globales
# =================================================================================

variable "project_name" {
  description = "Nombre del proyecto, usado para nombrar recursos."
  type        = string
  default     = "ares"
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)."
  type        = string
}

variable "aws_region" {
  description = "Región de AWS para el despliegue."
  type        = string
  default     = "us-east-1"
}

# ----------------------------------
# Network Configuration
# ----------------------------------
variable "vpc_cidr" {
  description = "Rango CIDR para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Rangos CIDR para las subredes públicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Rangos CIDR para las subredes privadas de la aplicación."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "db_subnets" {
  description = "Rangos CIDR para las subredes privadas de la base de datos."
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}

# ----------------------------------
# Database Configuration
# ----------------------------------
variable "db_instance_class" {
  description = "Clase de instancia para la base de datos RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento inicial para la base de datos en GB."
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Usuario master para la base de datos RDS."
  type        = string
  default     = "admin"
}

# ----------------------------------
# Compute (ECS) Configuration
# ----------------------------------
variable "container_port" {
  description = "Puerto que expone el contenedor de Spring Boot."
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "Unidades de CPU a asignar al contenedor ECS."
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "container_memory" {
  description = "Memoria en MiB a asignar al contenedor ECS."
  type        = number
  default     = 512 # 0.5 GB
}

variable "autoscale_min_tasks" {
  description = "Número mínimo de tareas para el servicio ECS."
  type        = number
  default     = 2
}

variable "autoscale_max_tasks" {
  description = "Número máximo de tareas para el servicio ECS."
  type        = number
  default     = 5
}

# ----------------------------------
# CI/CD Configuration
# ----------------------------------
variable "github_owner" {
  description = "Propietario (usuario u organización) del repositorio en GitHub."
  type        = string
}

variable "github_repo_infra" {
  description = "Nombre del repositorio de GitHub para la infraestructura."
  type        = string
}

variable "github_repo_app" {
  description = "Nombre del repositorio de GitHub para la aplicación."
  type        = string
}

variable "github_branch" {
  description = "Rama del repositorio que disparará los pipelines."
  type        = string
  default     = "main"
}
