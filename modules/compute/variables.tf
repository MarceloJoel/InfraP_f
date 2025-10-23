# modules/compute/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas (para el ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (para ECS)"
  type        = list(string)
}

# --- Security Groups ---
variable "alb_security_groups" {
  description = "Lista de IDs de Security Groups para el ALB"
  type        = list(string)
}

variable "ecs_web_api_security_groups" {
  description = "Lista de IDs de Security Groups para el servicio ECS Web API"
  type        = list(string)
}

variable "ecs_worker_security_groups" {
  description = "Lista de IDs de Security Groups para el servicio ECS Worker"
  type        = list(string)
}

# --- IAM Roles ---
variable "ecs_execution_role_arn" {
  description = "ARN del Rol de Ejecución de Tareas de ECS (común para ambos servicios)"
  type        = string
}

variable "ecs_web_api_task_role_arn" {
  description = "ARN del Rol de Tarea de ECS para la API Web"
  type        = string
}

variable "ecs_worker_task_role_arn" {
  description = "ARN del Rol de Tarea de ECS para el Worker"
  type        = string
}

# --- Recursos Externos ---
variable "web_api_ecr_repo_url" {
  description = "URL del repositorio ECR para la imagen de la aplicación"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN del secreto en Secrets Manager para la BD"
  type        = string
}

variable "frontend_s3_bucket_id" {
  description = "ID (nombre) del bucket S3 del frontend"
  type        = string
}

variable "frontend_s3_bucket_domain" {
  description = "Dominio regional del bucket S3 del frontend"
  type        = string
}

variable "frontend_s3_bucket_arn" {
  description = "ARN del bucket S3 del frontend"
  type        = string
}

variable "tags" {
  description = "Mapa de etiquetas comunes"
  type        = map(string)
  default     = {}
}

