# modules/compute/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán los recursos de cómputo."
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas (para el ALB)."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (para ECS)."
  type        = list(string)
}

variable "alb_security_groups" {
  description = "Lista de IDs de Security Groups para el ALB."
  type        = list(string)
}

variable "ecs_web_api_security_groups" {
  description = "Lista de IDs de Security Groups para el servicio ECS Web API."
  type        = list(string)
}

variable "ecs_worker_security_groups" {
  description = "Lista de IDs de Security Groups para el servicio ECS Worker."
  type        = list(string)
}

variable "web_api_ecr_repo_url" {
  description = "URL del repositorio ECR que contiene la imagen de la aplicación."
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN del rol de ejecución de ECS (para jalar imágenes y enviar logs)."
  type        = string
}

variable "ecs_web_api_task_role_arn" {
  description = "ARN del rol de tarea de la API Web (permisos de la app)."
  type        = string
}

variable "ecs_worker_task_role_arn" {
  description = "ARN del rol de tarea del Worker (permisos de la app)."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN del secreto en Secrets Manager que contiene la contraseña de la BD."
  type        = string
}

variable "frontend_s3_bucket_domain" {
  description = "El nombre de dominio regional del bucket S3 del frontend."
  type        = string
}

variable "frontend_s3_bucket_id" {
  description = "El ID (nombre) del bucket S3 del frontend."
  type        = string
}

variable "frontend_s3_bucket_arn" {
  description = "El ARN del bucket S3 del frontend."
  type        = string
}

