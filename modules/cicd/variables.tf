# modules/cicd/variables.tf

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

variable "github_owner" {
  description = "Propietario (usuario u organización) del repositorio en GitHub."
  type        = string
}

variable "github_repo_infra" {
  description = "Nombre del repositorio de GitHub para el código de infraestructura."
  type        = string
}

variable "github_repo_app" {
  description = "Nombre del repositorio de GitHub para el código de la aplicación."
  type        = string
}

variable "github_branch" {
  description = "Nombre de la rama principal (ej. 'main' o 'master')."
  type        = string
}

variable "codestar_connection_arn" {
  description = "El ARN de la conexión de AWS CodeStar a GitHub (creada manualmente)."
  type        = string
}

variable "codepipeline_artifacts_bucket" {
  description = "Nombre del bucket S3 para los artefactos de CodePipeline."
  type        = string
}

variable "web_api_ecr_repo_name" {
  description = "Nombre del repositorio ECR para la API web."
  type        = string
}

variable "frontend_s3_bucket_id" {
  description = "ID (nombre) del bucket S3 para el frontend."
  type        = string
}

variable "cloudfront_id" {
  description = "ID de la distribución de CloudFront."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del clúster de ECS."
  type        = string
}

variable "ecs_web_api_service_name" {
  description = "Nombre del servicio ECS de la API Web."
  type        = string
}

variable "ecs_worker_service_name" {
  description = "Nombre del servicio ECS del Worker."
  type        = string
}

variable "frontend_app_path" {
  description = "Ruta relativa dentro del repo al build del frontend (ej. 'frontend/dist/app-name')"
  type        = string
}

