# modules/storage/outputs.tf
# Expone la información de los buckets y el repositorio ECR

output "frontend_s3_bucket_id" {
  description = "El ID (nombre) del bucket S3 para el frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_s3_bucket_domain" {
  description = "El nombre de dominio regional del bucket S3 del frontend"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_s3_bucket_arn" {
  description = "El ARN del bucket S3 del frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "codepipeline_artifacts_bucket_name" {
  description = "El nombre del bucket S3 para los artefactos de CodePipeline"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "web_api_ecr_repo_url" {
  description = "La URL del repositorio ECR para la API web"
  value       = aws_ecr_repository.web_api.repository_url
}

output "web_api_ecr_repo_name" {
  description = "El nombre del repositorio ECR para la API web"
  value       = aws_ecr_repository.web_api.name
}

