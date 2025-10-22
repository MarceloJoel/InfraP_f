# Módulo de Almacenamiento: S3 Buckets, ECR Repository

# Bucket S3 para el frontend de Angular
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${var.aws_account_id}"
  # Forzar HTTPS se configura en la distribución de CloudFront
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html" # Para que Angular maneje el ruteo
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket S3 para assets (ej. imágenes subidas por usuarios)
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-${var.environment}-${var.aws_account_id}"
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Repositorio ECR para la aplicación Spring Boot
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Bucket para los artefactos de CodePipeline
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts-${var.environment}"

  # Previene la eliminación accidental del bucket
  lifecycle {
    prevent_destroy = false
  }
}

