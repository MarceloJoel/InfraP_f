# modules/database/outputs.tf
# Expone la información de conexión de la BD

output "db_endpoint" {
  description = "El endpoint de conexión de la instancia RDS"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "El ARN del secreto en Secrets Manager que contiene la contraseña de la BD"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

