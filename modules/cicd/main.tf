# Módulo de CI/CD: CodePipeline, CodeBuild

# Rol para CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

# Rol para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

# TODO: Añadir políticas a los roles para que puedan acceder a S3, ECR, ECS, y ejecutar Terraform.

# Conexión a GitHub (requiere configuración manual en la consola de AWS)
resource "aws_codestarconnections_connection" "github" {
  provider_type = "GitHub"
  name          = "${var.project_name}-github-connection-${var.environment}"
}

# --- Pipeline de Infraestructura ---
resource "aws_codepipeline" "infra_pipeline" {
  name     = "${var.project_name}-infra-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = "codepipeline-artifacts-bucket-name" # Se necesita un bucket para los artefactos
  }

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
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo_infra}"
        BranchName       = var.github_branch
      }
    }
  }

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

resource "aws_codebuild_project" "infra_apply" {
  name          = "${var.project_name}-infra-apply-${var.environment}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "20"

  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/infra_apply.yml"
  }
}

# --- Pipeline de Aplicación ---
# (Se omite por brevedad, pero seguiría una estructura similar al de infraestructura)
# - Etapa Source: Conecta a github_repo_app
# - Etapa Build: Usa CodeBuild para 'docker build' y 'docker push' a ECR (buildspec/app_build.yml)
# - Etapa Deploy: Usa CodeBuild para 'terraform apply' que actualiza el servicio ECS con la nueva imagen.
