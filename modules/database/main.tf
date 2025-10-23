# modules/database/main.tf
# Define la instancia de RDS y el secreto en Secrets Manager

# 1. Secreto para la contraseña de la BD
# Genera una contraseña aleatoria y la almacena en AWS Secrets Manager
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-password-${var.environment}"
  description = "Password for the RDS database"

  # Para entornos 'dev', permite la eliminación inmediata.
  # Para 'prod', deberías cambiar esto a 30 días.
  recovery_window_in_days = (var.environment == "prod" ? 30 : 0)

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# 2. Instancia de Base de Datos RDS
resource "aws_db_instance" "main" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  identifier             = "${var.project_name}-db-${var.environment}"

  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result # Obtiene la contraseña del recurso random

  db_subnet_group_name   = var.db_subnet_group_name  # Depende del módulo 'network'
  vpc_security_group_ids = var.db_security_group_ids # Depende del módulo 'security'

  multi_az               = (var.environment == "prod" ? true : false) # Multi-AZ solo para prod
  storage_type           = "gp2"

  # Almacenamiento cifrado
  storage_encrypted      = true

  # Desactiva la eliminación accidental en producción
  deletion_protection    = (var.environment == "prod" ? true : false)

  # Permite que Terraform ignore cambios en la contraseña fuera de banda
  lifecycle {
    ignore_changes = [password]
  }

  skip_final_snapshot    = (var.environment == "prod" ? false : true)

  tags = var.tags
}

