# modules/storage/main.tf
# Define los buckets S3 y el repositorio ECR

# 1. Bucket S3 para el hosting del frontend (Angular)
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"

  tags = var.tags
}

# Bloquea el acceso público, CloudFront accederá via OAC (Origin Access Control)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Bucket S3 para los artefactos de CodePipeline
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts-${var.environment}"

  # Previene la eliminación accidental si el pipeline lo está usando
  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

# 3. Repositorio ECR para la API Web (Spring Boot)
resource "aws_ecr_repository" "web_api" {
  name                 = "${var.project_name}/web-api"
  image_tag_mutability = "MUTABLE" # Permite sobrescribir tags como 'latest'

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Política de limpieza de ECR:
# Mantiene solo las últimas 5 imágenes. Esto es crucial para no acumular costos.
resource "aws_ecr_lifecycle_policy" "web_api_policy" {
  repository = aws_ecr_repository.web_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

