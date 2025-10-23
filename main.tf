# Archivo Principal - Orquesta los módulos

# -----------------------------------------------------------------
# Lógica de Datos y Variables Locales
# -----------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------
# Módulos (en orden de dependencia)
# -----------------------------------------------------------------

# 1. Red (VPC, Subnets)
module "network" {
  source = "./modules/network"

  project_name      = var.project_name
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  public_sn_cidrs   = var.public_sn_cidrs
  private_sn_cidrs  = var.private_sn_cidrs
  database_sn_cidrs = var.database_sn_cidrs
  tags              = local.tags
}

# 2. Seguridad (Roles base y Security Groups)
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id # Depende de 'network'
  tags         = local.tags
}

# 3. Base de Datos (RDS, Secret)
module "database" {
  source = "./modules/database"

  project_name           = var.project_name
  environment            = var.environment
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_name                = var.db_name
  db_username            = var.db_username
  db_subnet_group_name   = module.network.database_subnet_group_name # Depende de 'network'
  db_security_group_ids  = [module.security.db_sg_id]                # Depende de 'security'
  tags                   = local.tags
}

# 4. Almacenamiento (S3, ECR)
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags
  account_id   = local.account_id
}

# 5. Cómputo (ALB, ECS, SQS, CloudFront y Políticas de IAM)
# Este módulo une todo
module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids

  # Security Groups (de 'security')
  alb_security_groups         = [module.security.alb_sg_id]
  ecs_web_api_security_groups = [module.security.ecs_web_api_sg_id]
  ecs_worker_security_groups  = [module.security.ecs_worker_sg_id]

  # Repositorio ECR (de 'storage')
  web_api_ecr_repo_url = module.storage.web_api_ecr_repo_url

  # Roles de ECS (de 'security')
  ecs_execution_role_arn    = module.security.ecs_execution_role_arn
  ecs_web_api_task_role_arn = module.security.ecs_web_api_task_role_arn
  ecs_worker_task_role_arn  = module.security.ecs_worker_task_role_arn

  # Secreto (de 'database')
  db_secret_arn = module.database.db_secret_arn

  # Frontend Bucket (de 'storage')
  frontend_s3_bucket_domain = module.storage.frontend_s3_bucket_domain
  frontend_s3_bucket_id     = module.storage.frontend_s3_bucket_id
  frontend_s3_bucket_arn    = module.storage.frontend_s3_bucket_arn

  tags = local.tags
}

# 6. CI/CD (Pipelines, CodeBuild)
module "cicd" {
  source = "./modules/cicd"

  project_name            = var.project_name
  environment             = var.environment
  tags                    = local.tags
  github_owner            = var.github_owner
  github_repo_infra       = var.github_repo_infra
  github_repo_app         = var.github_repo_app
  github_branch           = var.github_branch
  codestar_connection_arn = var.codestar_connection_arn

  # Recursos creados en otros módulos
  codepipeline_artifacts_bucket = module.storage.codepipeline_artifacts_bucket_name
  web_api_ecr_repo_name         = module.storage.web_api_ecr_repo_name
  frontend_s3_bucket_id         = module.storage.frontend_s3_bucket_id
  cloudfront_id                 = module.compute.cloudfront_id

  # Nombres de servicios para el deploy
  ecs_cluster_name          = module.compute.ecs_cluster_name
  ecs_web_api_service_name  = module.compute.ecs_web_api_service_name
  ecs_worker_service_name   = module.compute.ecs_worker_service_name

  frontend_app_path     = var.frontend_app_path
}

