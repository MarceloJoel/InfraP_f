# =================================================================================
# Salidas Principales del Despliegue
# =================================================================================

output "alb_dns_name" {
  description = "DNS público del Application Load Balancer para acceder a la API."
  value       = module.compute.alb_dns_name
}

output "frontend_s3_bucket_name" {
  description = "Nombre del bucket S3 que aloja el frontend de Angular."
  value       = module.storage.frontend_s3_bucket_id
}

output "cloudfront_distribution_domain" {
  description = "Dominio de la distribución de CloudFront para acceder al frontend."
  value       = "TO-DO: Add CloudFront module and output" # Se debe añadir un módulo para CloudFront y Route 53
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR para las imágenes Docker."
  value       = module.storage.ecr_repo_url
}

output "db_secret_arn" {
  description = "ARN del secreto en AWS Secrets Manager para la base de datos."
  value       = module.database.db_secret_arn
}

output "ecs_cluster_name" {
  description = "Nombre del clúster de ECS."
  value       = module.compute.ecs_cluster_name
}
