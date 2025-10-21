output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}
output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
