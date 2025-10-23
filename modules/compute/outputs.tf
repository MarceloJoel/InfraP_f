# modules/compute/outputs.tf
# Salidas del Módulo de Cómputo

output "alb_dns_name" {
  description = "El DNS (URL) del Application Load Balancer para la API."
  value       = aws_lb.main.dns_name
}

output "cloudfront_domain_name" {
  description = "El DNS (URL) de la distribución de CloudFront para el frontend."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_id" {
  description = "El ID de la distribución de CloudFront (para invalidaciones de caché)."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.main.name
}

output "ecs_web_api_service_name" {
  description = "Nombre del servicio ECS de la API Web."
  value       = aws_ecs_service.web_api.name
}

output "ecs_worker_service_name" {
  description = "Nombre del servicio ECS del Worker."
  value       = aws_ecs_service.worker.name
}
