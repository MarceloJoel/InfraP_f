# Módulo de Seguridad: Security Groups, IAM Roles

# Security Group para el Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Permite trafico web (HTTP/HTTPS) hacia el ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para los contenedores ECS
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg-${var.environment}"
  description = "Permite trafico desde el ALB hacia los contenedores ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080 # Puerto de la aplicación Spring Boot
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permite salida a internet para APIs externas, etc.
  }
}

# Security Group para la base de datos RDS
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Permite trafico desde los contenedores ECS hacia la DB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306 # Puerto de MySQL
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

# --- IAM Roles ---

# Rol para las tareas de ECS (permisos de la aplicación)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Política para que ECS pueda leer el secreto de la DB
resource "aws_iam_policy" "ecs_secrets_policy" {
  name = "${var.project_name}-ecs-secrets-policy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["secretsmanager:GetSecretValue"],
      Effect   = "Allow",
      Resource = "*" # Se podría restringir al ARN específico del secreto
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# Rol de ejecución de tareas ECS (permisos para iniciar el contenedor)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Política gestionada por AWS para la ejecución de tareas
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
