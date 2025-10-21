# Módulo de Base de Datos: RDS, Secrets Manager

# Subnet group para RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.db_subnets_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# Secreto para la contraseña de la base de datos
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-credentials-${var.environment}"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master_password.result
  })
}

# Generador de contraseña aleatoria
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Instancia de base de datos RDS MySQL
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db-${var.environment}"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2"

  username             = jsondecode(aws_secretsmanager_secret_version.db_password.secret_string).username
  password             = jsondecode(aws_secretsmanager_secret_version.db_password.secret_string).password

  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  multi_az             = true # Alta disponibilidad
  storage_encrypted    = true # Cifrado en reposo
  skip_final_snapshot  = true # Para entornos de no-producción, en prod sería false
}
