# modules/cicd/outputs.tf

output "infra_pipeline_arn" {
  description = "ARN of the infrastructure pipeline"
  value       = aws_codepipeline.infra_pipeline.arn
}

output "app_pipeline_arn" {
  description = "ARN of the application pipeline"
  value       = aws_codepipeline.app_pipeline.arn
}

