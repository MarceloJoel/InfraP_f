# modules/cicd/main.tf

# -----------------------------------------------------------------
# Roles de IAM para los Pipelines
# -----------------------------------------------------------------

# 1. Rol para CodePipeline (El "Jefe de Obra")
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role-${var.environment}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

# 2. Rol para CodeBuild (El "Constructor" que ejecuta Terraform, Docker, etc.)
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role-${var.environment}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

# -----------------------------------------------------------------
# Políticas de IAM (Permisos)
# -----------------------------------------------------------------

# 1. Política para el Rol de CodePipeline
data "aws_iam_policy_document" "codepipeline_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.codepipeline_artifacts_bucket}",
      "arn:aws:s3:::${var.codepipeline_artifacts_bucket}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = [var.codestar_connection_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"] # Se puede restringir a los ARNs de los proyectos de CodeBuild
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = "${var.project_name}-codepipeline-policy-${var.environment}"
  policy = data.aws_iam_policy_document.codepipeline_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# 2. Política para el Rol de CodeBuild
# NOTA: Para ejecutar Terraform, este rol necesita permisos para gestionar
# todos los recursos. Para un entorno de desarrollo, 'AdministratorAccess'
# es la forma más simple de asegurar que Terraform funcione sin errores de permisos.
# En producción, esto se restringiría al mínimo privilegio.
resource "aws_iam_role_policy_attachment" "codebuild_admin_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CodeBuild también necesita permisos completos de ECR para construir y subir imágenes.
resource "aws_iam_role_policy_attachment" "codebuild_ecr_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}


# -----------------------------------------------------------------
# Pipeline 1: Infraestructura (CI/CD para Terraform)
# -----------------------------------------------------------------

resource "aws_codebuild_project" "infra_apply" {
  name          = "${var.project_name}-infra-apply-${var.environment}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "30" # 30 minutos de timeout para Terraform
  tags          = var.tags

  artifacts {
    type = "CODEPIPELINE" # Corregido
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0" # Imagen estándar con Terraform
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE" # Corregido
    buildspec = "buildspec/infra_apply.yml"
  }
}

resource "aws_codepipeline" "infra_pipeline" {
  name     = "${var.project_name}-infra-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = var.tags

  artifact_store {
    type     = "S3"
    location = var.codepipeline_artifacts_bucket
  }

  # Etapa 1: Fuente (GitHub)
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo_infra}"
        BranchName       = var.github_branch
      }
    }
  }

  # Etapa 2: Aplicar (CodeBuild + Terraform)
  stage {
    name = "Apply"
    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.infra_apply.name
      }
    }
  }
}


# -----------------------------------------------------------------
# Pipeline 2: Aplicación (CI/CD para Angular + Spring Boot)
# -----------------------------------------------------------------

# Proyecto CodeBuild para la Etapa de "Build" (Docker, NPM)
resource "aws_codebuild_project" "app_build" {
  name          = "${var.project_name}-app-build-${var.environment}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "20"
  tags          = var.tags

  # Privilegiado es necesario para construir imágenes Docker
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/app_build.yml"
  }
}

# Proyecto CodeBuild para la Etapa de "Deploy" (Terraform, S3 Sync, CloudFront)
resource "aws_codebuild_project" "app_deploy" {
  name          = "${var.project_name}-app-deploy-${var.environment}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "20"
  tags          = var.tags

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # Pasamos todas las variables necesarias al script de deploy
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
    environment_variable {
      name  = "FRONTEND_BUCKET_ID"
      value = var.frontend_s3_bucket_id
    }
    environment_variable {
      name  = "CLOUDFRONT_ID"
      value = var.cloudfront_id
    }
    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = var.ecs_cluster_name
    }
    environment_variable {
      name  = "ECS_WEB_API_SERVICE_NAME"
      value = var.ecs_web_api_service_name
    }
    environment_variable {
      name  = "ECS_WORKER_SERVICE_NAME"
      value = var.ecs_worker_service_name
    }
    environment_variable {
      name  = "WEB_API_ECR_REPO_NAME"
      value = var.web_api_ecr_repo_name
    }
    environment_variable {
      name  = "FRONTEND_APP_PATH"
      value = var.frontend_app_path
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/app_deploy.yml"
  }
}


# Definición del Pipeline de Aplicación
resource "aws_codepipeline" "app_pipeline" {
  name     = "${var.project_name}-app-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = var.tags

  artifact_store {
    type     = "S3"
    location = var.codepipeline_artifacts_bucket
  }

  # Etapa 1: Fuente (GitHub)
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo_app}"
        BranchName       = var.github_branch
      }
    }
  }

  # Etapa 2: Build (CodeBuild - Docker/NPM)
  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"] # Pasa los artefactos a la siguiente etapa
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  # Etapa 3: Deploy (CodeBuild - Terraform/S3 Sync)
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build" # La categoría de Deploy de CodePipeline es diferente
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["build_output"] # Recibe los artefactos de la etapa anterior
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_deploy.name
      }
    }
  }
}

