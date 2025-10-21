# =================================================================================
# Variables para el Entorno de Producción (PROD)
# =================================================================================

environment = "prod"

# Configuración robusta para producción
db_instance_class     = "db.m5.large"
db_allocated_storage  = 100
autoscale_min_tasks   = 3
autoscale_max_tasks   = 10

# Reemplaza con tus datos de GitHub
github_owner      = "your-github-username"
github_repo_infra = "ares-infra"
github_repo_app   = "ares-app"
github_branch     = "main"
