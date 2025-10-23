# modules/network/outputs.tf
# Expone los IDs de los recursos de red para que otros módulos los usen.

output "vpc_id" {
  description = "El ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas de la aplicación"
  value       = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "Lista de IDs de las subredes privadas de la base de datos"
  value       = [for s in aws_subnet.database : s.id]
}

output "database_subnet_group_name" {
  description = "Nombre del grupo de subredes de RDS"
  value       = aws_db_subnet_group.database.name
}

