# =================================================================================
# Archivo Raíz de Terraform (main.tf)
# ---------------------------------------------------------------------------------
# Este archivo es el punto de entrada. Define los módulos que componen la
# infraestructura y pasa las variables necesarias a cada uno.
# =================================================================================

# ---------------------------------------------------------------------------------
# Módulo de Red (VPC, Subnets, etc.)
# ---------------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  db_subnets      = var.db_subnets
}

# ---------------------------------------------------------------------------------
# Módulo de Seguridad (Security Groups, IAM Roles)
# ---------------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
  vpc_cidr     = var.vpc_cidr
}

# ---------------------------------------------------------------------------------
# Módulo de Almacenamiento (S3, ECR)
# ---------------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
}

# ---------------------------------------------------------------------------------
# Módulo de Base de Datos (RDS, Secrets Manager)
# ---------------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  db_subnets_ids        = module.network.db_subnets_ids
  db_security_group_id  = module.security.db_sg_id
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_username           = var.db_username
  # La contraseña se genera y gestiona en Secrets Manager dentro del módulo
}

# ---------------------------------------------------------------------------------
# Módulo de Cómputo (ALB, ECS Fargate)
# ---------------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  public_subnets_ids   = module.network.public_subnets_ids
  private_subnets_ids  = module.network.private_subnets_ids
  alb_sg_id            = module.security.alb_sg_id
  ecs_sg_id            = module.security.ecs_sg_id
  ecs_task_role_arn    = module.security.ecs_task_role_arn
  ecs_exec_role_arn    = module.security.ecs_execution_role_arn
  ecr_repo_url         = module.storage.ecr_repo_url
  db_secret_arn        = module.database.db_secret_arn
  container_port       = var.container_port
  container_cpu        = var.container_cpu
  container_memory     = var.container_memory
  autoscale_min_tasks  = var.autoscale_min_tasks
  autoscale_max_tasks  = var.autoscale_max_tasks
  log_group_name       = module.monitoring.ecs_log_group_name
}

# ---------------------------------------------------------------------------------
# Módulo de Monitoreo (CloudWatch)
# ---------------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
}

# ---------------------------------------------------------------------------------
# Módulo de CI/CD (CodePipeline, CodeBuild)
# ---------------------------------------------------------------------------------
module "cicd" {
  source = "./modules/cicd"

  project_name      = var.project_name
  environment       = var.environment
  github_owner      = var.github_owner
  github_repo_infra = var.github_repo_infra
  github_repo_app   = var.github_repo_app
  github_branch     = var.github_branch

  ecr_repo_name       = module.storage.ecr_repo_name
  ecs_cluster_name    = module.compute.ecs_cluster_name
  ecs_service_name    = module.compute.ecs_service_name
  frontend_bucket_id  = module.storage.frontend_s3_bucket_id
}
