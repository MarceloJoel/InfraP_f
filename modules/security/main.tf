# modules/security/main.tf
# Define todos los Security Groups (firewalls) y Roles de IAM (permisos)

# -----------------------------------------------------------------
# Security Groups (SGs)
# -----------------------------------------------------------------

# 1. SG para el Application Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Allows HTTP traffic from the internet to the ALB" # Sin tildes
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80 # Solo HTTP para esta versión general
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 2. SG para el servicio ECS Web API (Spring Boot)
resource "aws_security_group" "ecs_web_api_sg" {
  name        = "${var.project_name}-ecs-web-api-sg-${var.environment}"
  description = "Allows traffic from ALB and allows egress" # Sin tildes
  vpc_id      = var.vpc_id

  # INGRESS: Solo permite tráfico desde el ALB en el puerto de la app
  ingress {
    description     = "Allow from ALB"
    from_port       = 8080 # Puerto de la aplicación Spring Boot
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # EGRESS: Permite salida a internet (para NAT Gateway) y a la BD
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 3. SG para el servicio ECS Worker
resource "aws_security_group" "ecs_worker_sg" {
  name        = "${var.project_name}-ecs-worker-sg-${var.environment}"
  description = "Allows egress for worker to access DB and other services" # Sin tildes
  vpc_id      = var.vpc_id

  # INGRESS: Sin tráfico de entrada. El worker inicia la comunicación (pull de SQS).
  # Dejamos el bloque 'ingress' vacío o lo omitimos.

  # EGRESS: Permite salida a internet (NAT) y a la BD/SQS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 4. SG para la Base de Datos RDS
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Allows traffic from application SGs (Web API and Worker)" # Sin tildes
  vpc_id      = var.vpc_id

  # INGRESS: Solo permite conexiones desde la API y el Worker
  ingress {
    description     = "Allow from ECS Web API"
    from_port       = 3306 # Puerto de MySQL
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_web_api_sg.id]
  }

  ingress {
    description     = "Allow from ECS Worker"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_worker_sg.id]
  }

  # EGRESS: Por defecto (restringido)

  tags = var.tags
}


# -----------------------------------------------------------------
# Roles de IAM para ECS
# -----------------------------------------------------------------

# 1. Rol de EJECUCIÓN de Tareas ECS (Común para ambos servicios)
# Permisos que necesita ECS para INICIAR tu contenedor (ej. jalar imagen de ECR, escribir logs)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role-${var.environment}"

  # Política de confianza (quién puede asumir este rol)
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

  tags = var.tags
}

# Adjuntamos la política base gestionada por AWS
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. Rol de TAREA de la Web API (Permisos de TU APLICACIÓN)
# Permisos que tu código Spring Boot necesita (ej. leer secretos, escribir en SQS)
resource "aws_iam_role" "ecs_web_api_task_role" {
  name = "${var.project_name}-ecs-web-api-task-role-${var.environment}"

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

  tags = var.tags
}

# 3. Rol de TAREA del Worker (Permisos de TU WORKER)
# Permisos que tu worker necesita (ej. leer secretos, leer/borrar de SQS)
resource "aws_iam_role" "ecs_worker_task_role" {
  name = "${var.project_name}-ecs-worker-task-role-${var.environment}"

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

  tags = var.tags
}

