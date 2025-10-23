# modules/compute/outputs.tf

output "alb_dns_name" {
  description = "El nombre DNS del Application Load Balancer (para la API)"
  value       = aws_lb.main.dns_name
}

output "cloudfront_id" {
  description = "El ID de la distribución de CloudFront (para el pipeline)"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_domain_name" {
  description = "El nombre de dominio de la distribución de CloudFront (para el frontend)"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "ecs_cluster_name" {
  description = "El nombre del clúster de ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_web_api_service_name" {
  description = "El nombre del servicio ECS de la API Web"
  value       = aws_ecs_service.web_api.name
}

output "ecs_worker_service_name" {
  description = "El nombre del servicio ECS del Worker"
  value       = aws_ecs_service.worker.name
}

