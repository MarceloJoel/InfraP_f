# Salidas Principales de la Infraestructura

output "frontend_url" {
  description = "URL del sitio web del frontend (CloudFront)"
  value       = "https://${module.compute.cloudfront_domain_name}" # CloudFront siempre usa HTTPS
}

output "api_url" {
  description = "URL del backend API (Application Load Balancer)"
  value       = "http://${module.compute.alb_dns_name}" # Usamos HTTP para esta versión general
}

output "db_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN del secreto de la base de datos en Secrets Manager"
  value       = module.database.db_secret_arn
  sensitive   = true
}

output "frontend_s3_bucket_name" {
  description = "Nombre del bucket S3 para el hosting del frontend"
  value       = module.storage.frontend_s3_bucket_id
}

output "web_api_ecr_repo_url" {
  description = "URL del repositorio ECR para la API web"
  value       = module.storage.web_api_ecr_repo_url
}

