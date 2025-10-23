# modules/compute/main.tf
# Define los recursos de cómputo: ALB, ECS (API y Worker), SQS y CloudFront

# --- AÑADIDO: Bloque para declarar los proveedores que este módulo necesita ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Declara el proveedor con alias para CloudFront
    "aws.us_east_1" = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
}

# --- Grupos de Logs ---
# Grupo de logs para el servicio API Web
resource "aws_cloudwatch_log_group" "web_api" {
  name              = "/ecs/${var.project_name}/web-api/${var.environment}"
  retention_in_days = 7
  tags              = var.tags
}

# Grupo de logs para el servicio Worker
resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project_name}/worker/${var.environment}"
  retention_in_days = 7
  tags              = var.tags
}

# --- SQS (Simple Queue Service) ---
# Cola de Mensajes Muertos (DLQ) para los mensajes que fallan
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-queue-dlq-${var.environment}"
  tags = var.tags
}

# Cola principal para el procesamiento asíncrono
resource "aws_sqs_queue" "main" {
  name = "${var.project_name}-queue-main-${var.environment}"

  # Redirige los mensajes que fallan 5 veces a la DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

# --- Application Load Balancer (para la API) ---
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = var.tags
}

# Target Group para la API Web
resource "aws_lb_target_group" "web_api" {
  name        = "${var.project_name}-tg-api-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/actuator/health" # Ruta de health check de Spring Boot
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.tags
}

# Listener HTTP (Puerto 80)
# Para esta versión "general", no usamos HTTPS (Puerto 443)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_api.arn
  }
}

# --- ECS (Elastic Container Service) ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"
  tags = var.tags
}

# --- Servicio 1: API Web (Spring Boot) ---
resource "aws_ecs_task_definition" "web_api" {
  family                   = "${var.project_name}-web-api-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512  # 0.5 vCPU
  memory                   = 1024 # 1 GB
  execution_role_arn       = var.ecs_execution_role_arn # Rol para que ECS pueda jalar la imagen ECR y enviar logs
  task_role_arn            = var.ecs_web_api_task_role_arn  # Rol para que la app pueda acceder a SQS y RDS

  container_definitions = jsonencode([
    {
      name      = "web-api-container"
      image     = "${var.web_api_ecr_repo_url}:latest" # Siempre jala la última imagen
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web_api.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "api"
        }
      }
      secrets = [
        {
          name      = "DB_SECRET_ARN" # Variable de entorno que la app usará
          valueFrom = var.db_secret_arn
        }
      ]
      environment = [
        {
          name  = "SQS_QUEUE_URL" # Variable de entorno para la URL de la cola
          value = aws_sqs_queue.main.url
        }
      ]
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "web_api" {
  name            = "${var.project_name}-web-api-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_api.arn
  desired_count   = 1 # Inicia con 1 contenedor
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = var.ecs_web_api_security_groups
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_api.arn
    container_name   = "web-api-container"
    container_port   = 8080
  }

  # Asegura que el servicio no intente iniciarse antes de que el listener esté listo
  depends_on = [aws_lb_listener.http]

  tags = var.tags
}

# --- Servicio 2: Worker Asíncrono ---
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project_name}-worker-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256  # 0.25 vCPU
  memory                   = 512  # 0.5 GB
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_worker_task_role_arn # Rol para que el worker pueda leer de SQS y acceder a RDS

  container_definitions = jsonencode([
    {
      name      = "worker-container"
      image     = "${var.web_api_ecr_repo_url}:latest" # Asumimos que el worker usa la misma imagen
      essential = true
      # Sin portMappings, ya que no recibe tráfico web
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "worker"
        }
      }
      secrets = [
        {
          name      = "DB_SECRET_ARN"
          valueFrom = var.db_secret_arn
        }
      ]
      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.main.url
        },
        {
          name  = "SQS_DLQ_URL"
          value = aws_sqs_queue.dlq.url
        }
      ]
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project_name}-worker-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1 # Inicia con 1 worker
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = var.ecs_worker_security_groups
  }

  # Sin load_balancer, ya que no atiende tráfico

  tags = var.tags
}

# --- Auto Scaling ---
# Auto Scaling para la API Web (basado en CPU)
resource "aws_appautoscaling_target" "web_api" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web_api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "web_api_cpu" {
  name               = "${var.project_name}-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web_api.resource_id
  scalable_dimension = aws_appautoscaling_target.web_api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.web_api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 75.0 # Mantiene el uso de CPU al 75%
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling para el Worker (basado en mensajes de SQS)
resource "aws_appautoscaling_target" "worker" {
  max_capacity       = 4
  min_capacity       = 1 # Puede ser 0 si quieres apagarlo cuando no hay trabajo
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_sqs" {
  name               = "${var.project_name}-worker-sqs-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker.resource_id
  scalable_dimension = aws_appautoscaling_target.worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 10.0 # Intenta mantener 10 mensajes por worker
    customized_metric_specification {
        metrc_name = "ApproximateNumberOfMessagesVisible"
        namespace   = "AWS/SQS"
        statistic   = "Sum"
        dimension {
          name = "Queuename"
          value = aws_sqs_queue.main.name
        }
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# --- CloudFront (para el Frontend) ---
data "aws_region" "current" {}

# Control de Acceso de Origen (OAC) para S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac-${var.environment}"
  description                       = "OAC for ${var.frontend_s3_bucket_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribución de CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  provider = aws.us_east_1 # CloudFront se gestiona mejor desde us-east-1

  origin {
    domain_name              = var.frontend_s3_bucket_domain
    origin_id                = var.frontend_s3_bucket_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name} frontend"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.frontend_s3_bucket_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Configuración para SPA (Single Page Application):
  # Redirige todos los errores (ej. /login, /dashboard) a index.html
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # Sin restricción geográfica
    }
  }

  # Para la versión "general", usamos el certificado por defecto de CloudFront
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# --- Política del Bucket S3 ---
# Esta política se crea aquí (en 'compute') porque depende de CloudFront.
# Le da permiso a CloudFront (y a nadie más) para leer el bucket.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.frontend_s3_bucket_arn}/*"] # Acceso a los objetos

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = var.frontend_s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}

